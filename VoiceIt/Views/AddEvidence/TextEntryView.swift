import SwiftUI

/// Text entry view for written evidence
struct TextEntryView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locationService) private var locationService
    
    @State private var bodyText = ""
    @State private var notes = ""
    @State private var isCritical = false
    @State private var includeLocation = false
    @State private var isQuickNote = false
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @FocusState private var isBodyFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Main text entry
                Section {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 200)
                        .focused($isBodyFocused)
                } header: {
                    HStack {
                        Text("Content")
                        Spacer()
                        Text("\(wordCount) words")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                
                // Additional notes
                Section("Additional Notes") {
                    TextField("Optional notes or context", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // Tags
                Section("Tags") {
                    // Existing tags
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                        
                                        Button {
                                            tags.removeAll { $0 == tag }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.voiceitPurple.opacity(0.2))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    // Add tag
                    HStack {
                        TextField("Add tag", text: $newTag)
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
                
                // Options
                Section("Options") {
                    Toggle("Quick Note", isOn: $isQuickNote)
                    Toggle("Mark as Critical", isOn: $isCritical)
                    Toggle("Include Location", isOn: $includeLocation)
                }
            }
            .navigationTitle("Text Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTextEntry()
                    }
                    .disabled(bodyText.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isBodyFocused = false
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                isBodyFocused = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var wordCount: Int {
        bodyText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    // MARK: - Add Tag
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        
        tags.append(trimmed)
        newTag = ""
    }
    
    // MARK: - Save Text Entry
    
    private func saveTextEntry() {
        guard !bodyText.isEmpty else { return }
        
        Task {
            do {
                // Get location if requested
                var locationSnapshot: LocationSnapshot?
                if includeLocation {
                    locationSnapshot = await locationService.createSnapshot()
                }
                
                let textEntry = TextEntry(
                    notes: notes,
                    locationSnapshot: locationSnapshot,
                    tags: tags,
                    isCritical: isCritical,
                    bodyText: bodyText,
                    isQuickNote: isQuickNote
                )
                
                modelContext.insert(textEntry)
                try modelContext.save()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save text entry: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    TextEntryView()
}

