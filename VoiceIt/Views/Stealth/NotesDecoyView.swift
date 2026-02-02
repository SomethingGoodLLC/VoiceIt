import SwiftUI

/// Decoy notes screen for stealth mode
struct NotesDecoyView: View {
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    
    @State private var notes = [
        Note(title: "Grocery List", date: Date(), preview: "Milk, eggs, bread, cheese..."),
        Note(title: "Meeting Notes", date: Date().addingTimeInterval(-86400), preview: "Discussed project timeline..."),
        Note(title: "Ideas", date: Date().addingTimeInterval(-172800), preview: "New app concept for productivity...")
    ]
    @State private var showingNewNote = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                List {
                    ForEach(notes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(note.title)
                                    .font(.headline)
                                Spacer()
                                Text(note.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(note.preview)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewNote = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    // Long press on "New Note" button to trigger Face ID/Biometrics
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.0)
                            .onEnded { _ in
                                triggerBiometricUnlock()
                            }
                    )
                }
            }
            .navigationDestination(isPresented: $showingNewNote) {
                DecoyNoteEditorView()
            }
        }
    }
    private func triggerBiometricUnlock() {
        Task {
            do {
                // Try biometrics ONLY first (no passcode fallback)
                try await authService.authenticateWithBiometrics(reason: "Unlock with \(authService.biometricType.displayName)")
                // If successful, deactivate stealth mode
                await MainActor.run {
                    stealthService.isStealthActive = false
                }
            } catch {
                // If biometrics fail, silently stay in stealth mode
                // User can still use passcode method via typing it in a note
                print("Biometric unlock failed: \(error.localizedDescription)")
            }
        }
    }
}

struct Note: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let preview: String
}

/// Decoy note editor that detects passcode entry
struct DecoyNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    
    @State private var text = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            TextEditor(text: $text)
                .font(.body)
                .padding()
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    checkForUnlock(newValue)
                }
        }
        .navigationTitle("New Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private func checkForUnlock(_ content: String) {
        // Check if the last character is a newline (Enter key)
        guard content.hasSuffix("\n") else { return }
        
        // Get the last line (excluding the newline)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        guard let lastLine = lines.dropLast().last else { return }
        
        let potentialPasscode = String(lastLine).trimmingCharacters(in: .whitespaces)
        
        do {
            if try authService.verifyPasscode(potentialPasscode) {
                Task { @MainActor in
                    stealthService.isStealthActive = false
                }
            }
        } catch {
            // Ignore errors
        }
    }
}

#Preview {
    NotesDecoyView()
}
