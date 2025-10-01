import SwiftUI
import AVFoundation

/// Enhanced voice recording view with transcription
struct VoiceRecorderView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locationService) private var locationService
    @Environment(\.encryptionService) private var encryptionService
    
    @State private var audioService = AudioRecordingService()
    @State private var transcriptionService = TranscriptionService()
    @State private var fileStorageService: FileStorageService?
    
    @State private var recordingURL: URL?
    @State private var transcription = ""
    @State private var notes = ""
    @State private var selectedCategories: [EvidenceCategory] = []
    @State private var isCritical = false
    @State private var includeLocation = false
    @State private var enableTranscription = true
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showingTranscriptionSetup = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Recording Controls
                    recordingSection
                    
                    // Transcription
                    if enableTranscription {
                        transcriptionSection
                    }
                    
                    // Categories
                    categoriesSection
                    
                    // Notes
                    notesSection
                    
                    // Options
                    optionsSection
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelRecording()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveRecording()
                        }
                        .disabled(!canSave)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                fileStorageService = FileStorageService(encryptionService: encryptionService)
                
                // Show transcription setup on first use OR if model is missing
                let setupCompleted = UserDefaults.standard.bool(forKey: "transcriptionSetupCompleted")
                print("📋 VoiceRecorder onAppear - transcriptionSetupCompleted: \(setupCompleted)")
                
                if !setupCompleted {
                    print("   → First time - showing transcription setup")
                    showingTranscriptionSetup = true
                } else {
                    // Check if Whisper/Auto mode was chosen but model is missing
                    let mode = transcriptionService.mode
                    let modelDownloaded = transcriptionService.isWhisperModelDownloaded
                    print("   → Setup completed previously. Mode: \(mode.displayName), Model downloaded: \(modelDownloaded)")
                    
                    if (mode == .whisper || mode == .auto) && !modelDownloaded {
                        print("   → Whisper/Auto selected but model missing - re-prompting setup")
                        // Reset flag to show setup again
                        UserDefaults.standard.set(false, forKey: "transcriptionSetupCompleted")
                        showingTranscriptionSetup = true
                    } else {
                        print("   → Setup valid, skipping")
                    }
                }
            }
            .sheet(isPresented: $showingTranscriptionSetup) {
                TranscriptionSetupView()
            }
        }
    }
    
    // MARK: - Recording Section
    
    private var recordingSection: some View {
        VStack(spacing: 20) {
            // Duration display
            Text(audioService.duration.formattedDuration)
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(audioService.isRecording ? Color.voiceitPurple : .secondary)
                .contentTransition(.numericText())
            
            // Waveform visualization
            waveformView
                .frame(height: 80)
                .padding(.horizontal)
            
            // Control buttons
            controlButtons
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(Array(audioService.waveformSamples.enumerated()), id: \.offset) { _, sample in
                RoundedRectangle(cornerRadius: 2)
                    .fill(audioService.isRecording && !audioService.isPaused ? 
                          Color.voiceitPurple : Color.voiceitPurple.opacity(0.3))
                    .frame(width: 3, height: max(4, CGFloat(sample) * 80))
            }
        }
        .animation(.easeInOut(duration: 0.1), value: audioService.waveformSamples)
    }
    
    private var controlButtons: some View {
        HStack(spacing: 40) {
            if !audioService.isRecording {
                // Start recording button
                Button {
                    startRecording()
                } label: {
                    VStack {
                        Image(systemName: "record.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(.red)
                        Text("Record")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // Pause/Resume button
                Button {
                    if audioService.isPaused {
                        audioService.resumeRecording()
                        if enableTranscription {
                            resumeTranscription()
                        }
                    } else {
                        audioService.pauseRecording()
                        transcriptionService.stopLiveTranscription()
                    }
                } label: {
                    VStack {
                        Image(systemName: audioService.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.voiceitPurple)
                        Text(audioService.isPaused ? "Resume" : "Pause")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Stop button
                Button {
                    stopRecording()
                } label: {
                    VStack {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                        Text("Stop")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Transcription Section
    
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Info banner when transcription is disabled
            if !UserDefaults.standard.bool(forKey: "autoTranscribeRecordings") && enableTranscription {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Transcription is available. Enable in Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            HStack {
                Label("Live Transcription", systemImage: "waveform")
                    .font(.headline)
                
                Spacer()
                
                // Transcription mode badge with actual method indicator
                VStack(spacing: 2) {
                    Menu {
                        ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                            Button {
                                transcriptionService.mode = mode
                            } label: {
                                Label(mode.displayName, systemImage: mode.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(transcriptionService.mode.badge)
                            Text(transcriptionService.mode.displayName)
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.voiceitPurple.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .disabled(audioService.isRecording)
                    
                    // Show what will actually be used
                    if transcriptionService.mode == .auto {
                        Text(transcriptionService.isWhisperModelDownloaded ? "Using: Whisper 🔒" : "Using: Apple ☁️")
                            .font(.system(size: 9))
                            .foregroundStyle(transcriptionService.isWhisperModelDownloaded ? .green : .orange)
                    } else if transcriptionService.mode == .whisper && !transcriptionService.isWhisperModelDownloaded {
                        Text("Model not downloaded")
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                    }
                }
                
                if audioService.isRecording && !audioService.isPaused {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        Text("Live")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if transcription.isEmpty {
                Text("Transcription will appear here as you speak...")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding()
            } else {
                ScrollView {
                    Text(transcription)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 100, maxHeight: 200)
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
            
            TextField("Add any additional context or details...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $enableTranscription) {
                Label("Live Transcription", systemImage: "text.badge.checkmark")
            }
            .disabled(audioService.isRecording)
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
    
    // MARK: - Recording Controls
    
    private func startRecording() {
        Task {
            do {
                // Check permissions
                guard await audioService.requestPermission() else {
                    throw AudioRecordingError.permissionDenied
                }
                
                if enableTranscription {
                    guard await transcriptionService.requestPermission() else {
                        throw TranscriptionError.permissionDenied
                    }
                }
                
                // Start recording
                let url = try await audioService.startRecording()
                recordingURL = url
                
                // Start transcription if enabled
                // NOTE: Only use live transcription for Apple mode
                // Whisper mode = privacy first, no Apple services at all!
                if enableTranscription && transcriptionService.mode == .apple {
                    try await transcriptionService.startLiveTranscription { newTranscription in
                        Task { @MainActor in
                            transcription = newTranscription
                        }
                    }
                } else if enableTranscription {
                    // For Whisper/Auto modes: show "Transcription will be generated when saving..."
                    Task { @MainActor in
                        transcription = "[Transcription will be generated when saving with Whisper]"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func stopRecording() {
        Task {
            _ = await audioService.stopRecording()
            transcriptionService.stopLiveTranscription()
        }
    }
    
    private func resumeTranscription() {
        Task {
            do {
                try await transcriptionService.startLiveTranscription { newTranscription in
                    Task { @MainActor in
                        transcription = newTranscription
                    }
                }
            } catch {
                print("Failed to resume transcription: \(error)")
            }
        }
    }
    
    private func cancelRecording() {
        Task {
            if audioService.isRecording {
                _ = await audioService.stopRecording()
                transcriptionService.stopLiveTranscription()
            }
            
            // Delete recording if exists
            if let url = recordingURL {
                try? audioService.deleteRecording(at: url)
            }
            
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func saveRecording() {
        guard let url = recordingURL else { return }
        
        isSaving = true
        
        Task {
            do {
                // Get location if requested
                var locationSnapshot: LocationSnapshot?
                if includeLocation {
                    locationSnapshot = await locationService.createSnapshot()
                }
                
                // Transcribe with selected method (Whisper/Apple/Auto) BEFORE moving file
                var finalTranscription = ""
                var transcriptionMethod: String? = nil
                
                if enableTranscription {
                    print("🎯 Transcribing with \(transcriptionService.mode.displayName) for final save...")
                    do {
                        // For Apple mode: use live transcription if available, otherwise re-transcribe
                        if transcriptionService.mode == .apple && !transcription.isEmpty && !transcription.contains("[Transcription will be generated") {
                            finalTranscription = transcription
                            transcriptionMethod = TranscriptionMethod.apple.rawValue
                            print("   ✅ Using live Apple transcription")
                        } else {
                            // For Whisper/Auto: always transcribe from file (no Apple services used)
                            let result = try await transcriptionService.transcribeAudioFile(at: url)
                            finalTranscription = result.text
                            transcriptionMethod = result.method.rawValue
                            print("   ✅ Final transcription method: \(result.method.rawValue)")
                        }
                    } catch {
                        print("   ⚠️ Transcription failed: \(error)")
                        // Only fall back to live transcription if it exists and was from Apple
                        if transcriptionService.mode == .apple && !transcription.isEmpty {
                            finalTranscription = transcription
                            transcriptionMethod = TranscriptionMethod.apple.rawValue
                        } else {
                            transcriptionMethod = nil
                        }
                    }
                }
                
                // Now save and encrypt audio file
                guard let fileStorage = fileStorageService else {
                    throw FileStorageError.encryptionFailed
                }
                
                let (filePath, fileSize, duration) = try await fileStorage.saveAudioFile(url)
                
                // Create voice note
                let voiceNote = VoiceNote(
                    notes: notes,
                    locationSnapshot: locationSnapshot,
                    tags: selectedCategories.map { $0.rawValue },
                    isCritical: isCritical,
                    audioFilePath: filePath,
                    duration: duration,
                    transcription: finalTranscription.isEmpty ? nil : finalTranscription,
                    transcriptionMethod: transcriptionMethod,
                    audioFormat: "m4a",
                    fileSize: fileSize
                )
                
                await MainActor.run {
                    modelContext.insert(voiceNote)
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
                    errorMessage = "Failed to save recording: \(error.localizedDescription)"
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
    
    private var canSave: Bool {
        recordingURL != nil && !audioService.isRecording
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: EvidenceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title3)
                
                Text(category.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.color.opacity(0.2) : Color(uiColor: .tertiarySystemGroupedBackground))
            .foregroundStyle(isSelected ? category.color : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? category.color : .clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    VoiceRecorderView()
        .modelContainer(for: [VoiceNote.self], inMemory: true)
}