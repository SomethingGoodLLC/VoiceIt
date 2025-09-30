import SwiftUI
import Speech

/// Enhanced text entry view with templates and voice-to-text
struct TextEntryView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locationService) private var locationService
    
    @State private var transcriptionService = TranscriptionService()
    
    @State private var bodyText = ""
    @State private var notes = ""
    @State private var selectedCategories: [EvidenceCategory] = []
    @State private var isCritical = false
    @State private var includeLocation = false
    @State private var isQuickNote = false
    
    @State private var showingTemplates = false
    @State private var isTranscribing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    @FocusState private var isBodyFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Main text editor
                    textEditorSection
                    
                    // Quick templates (if no text yet)
                    if bodyText.isEmpty {
                        templatesSection
                    }
                    
                    // Categories
                    if !bodyText.isEmpty {
                        categoriesSection
                        notesSection
                        optionsSection
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Text Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stopTranscribing()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveTextEntry()
                        }
                        .disabled(bodyText.isEmpty)
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
    
    // MARK: - Text Editor Section
    
    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Content", systemImage: "doc.text")
                    .font(.headline)
                
                Spacer()
                
                // Character count
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Voice-to-text toggle
                Button {
                    if isTranscribing {
                        stopTranscribing()
                    } else {
                        startTranscribing()
                    }
                } label: {
                    Image(systemName: isTranscribing ? "mic.fill" : "mic")
                        .foregroundStyle(isTranscribing ? .red : Color.voiceitPurple)
                        .font(.title3)
                }
            }
            
            TextEditor(text: $bodyText)
                .frame(minHeight: 200)
                .focused($isBodyFocused)
                .padding(8)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isTranscribing ? Color.red : Color.clear, lineWidth: 2)
                )
            
            if isTranscribing {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.red)
                        .symbolEffect(.variableColor.iterative)
                    
                    Text("Listening...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Templates Section
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quick Templates", systemImage: "text.badge.plus")
                    .font(.headline)
                
                Spacer()
                
                Text("Tap to use")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(TextTemplate.allCases) { template in
                    Button {
                        useTemplate(template)
                    } label: {
                        HStack {
                            Image(systemName: template.icon)
                                .frame(width: 24)
                                .foregroundStyle(Color.voiceitPurple)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Categories", systemImage: "tag.fill")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(EvidenceCategory.allCases) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Additional Notes", systemImage: "note.text")
                .font(.headline)
            
            TextField("Optional context or details...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $isQuickNote) {
                Label("Quick Note", systemImage: "bolt.fill")
            }
            .padding()
            
            Divider()
            
            Toggle(isOn: $isCritical) {
                Label("Mark as Critical", systemImage: "exclamationmark.triangle.fill")
            }
            .padding()
            
            Divider()
            
            Toggle(isOn: $includeLocation) {
                Label("Include Location", systemImage: "location.fill")
            }
            .padding()
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Computed Properties
    
    private var wordCount: Int {
        bodyText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    // MARK: - Templates
    
    private func useTemplate(_ template: TextTemplate) {
        bodyText = template.content
        isBodyFocused = true
    }
    
    // MARK: - Transcription
    
    private func startTranscribing() {
        Task {
            do {
                guard await transcriptionService.requestPermission() else {
                    throw TranscriptionError.permissionDenied
                }
                
                isTranscribing = true
                isBodyFocused = false
                
                try await transcriptionService.startLiveTranscription { newTranscription in
                    Task { @MainActor in
                        bodyText = newTranscription
                    }
                }
            } catch {
                await MainActor.run {
                    isTranscribing = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func stopTranscribing() {
        transcriptionService.stopLiveTranscription()
        isTranscribing = false
    }
    
    // MARK: - Save Text Entry
    
    private func saveTextEntry() {
        guard !bodyText.isEmpty else { return }
        
        stopTranscribing()
        isSaving = true
        
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
                    tags: selectedCategories.map { $0.rawValue },
                    isCritical: isCritical,
                    bodyText: bodyText,
                    isQuickNote: isQuickNote
                )
                
                await MainActor.run {
                    modelContext.insert(textEntry)
                }
                
                try modelContext.save()
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save text entry: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func toggleCategory(_ category: EvidenceCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.removeAll { $0 == category }
        } else {
            selectedCategories.append(category)
        }
    }
}

// MARK: - Text Template

enum TextTemplate: String, CaseIterable, Identifiable {
    case heSaid = "He said..."
    case heDid = "He did..."
    case iFelt = "I felt..."
    case incident = "Incident report"
    case witness = "What I witnessed..."
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .heSaid:
            return "He said..."
        case .heDid:
            return "He did..."
        case .iFelt:
            return "I felt..."
        case .incident:
            return "Incident Report"
        case .witness:
            return "What I witnessed..."
        }
    }
    
    var icon: String {
        switch self {
        case .heSaid:
            return "text.bubble"
        case .heDid:
            return "hand.raised"
        case .iFelt:
            return "heart"
        case .incident:
            return "exclamationmark.triangle"
        case .witness:
            return "eye"
        }
    }
    
    var description: String {
        switch self {
        case .heSaid:
            return "Record verbal statements"
        case .heDid:
            return "Document actions"
        case .iFelt:
            return "Describe your feelings"
        case .incident:
            return "Detailed incident documentation"
        case .witness:
            return "Record observations"
        }
    }
    
    var content: String {
        switch self {
        case .heSaid:
            return """
            He said: ""
            
            Date: \(Date().formatted(date: .long, time: .shortened))
            
            Context: 
            
            """
        case .heDid:
            return """
            He did: 
            
            Date: \(Date().formatted(date: .long, time: .shortened))
            
            What happened: 
            
            """
        case .iFelt:
            return """
            I felt: 
            
            Date: \(Date().formatted(date: .long, time: .shortened))
            
            My emotional state: 
            
            """
        case .incident:
            return """
            INCIDENT REPORT
            
            Date: \(Date().formatted(date: .long, time: .shortened))
            
            What happened:
            
            
            Who was involved:
            
            
            Where it happened:
            
            
            Additional details:
            
            """
        case .witness:
            return """
            What I witnessed:
            
            Date: \(Date().formatted(date: .long, time: .shortened))
            
            What I saw/heard: 
            
            """
        }
    }
}

#Preview {
    TextEntryView()
        .modelContainer(for: [TextEntry.self], inMemory: true)
}