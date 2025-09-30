import SwiftUI
import AVFoundation

/// Voice recording view
struct VoiceRecorderView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locationService) private var locationService
    @Environment(\.encryptionService) private var encryptionService
    
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var notes = ""
    @State private var isCritical = false
    @State private var includeLocation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Recording controls
                Section {
                    VStack(spacing: 20) {
                        // Duration display
                        Text(recordingDuration.formattedDuration)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.voiceitPurple)
                        
                        // Waveform placeholder
                        waveformView
                        
                        // Control buttons
                        HStack(spacing: 30) {
                            if !isRecording {
                                recordButton
                            } else {
                                pauseButton
                                stopButton
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                // Notes
                Section("Notes") {
                    TextField("Add notes about this recording", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Options
                Section("Options") {
                    Toggle("Mark as Critical", isOn: $isCritical)
                    Toggle("Include Location", isOn: $includeLocation)
                }
            }
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecording()
                    }
                    .disabled(recordingDuration == 0)
                }
            }
            .onReceive(timer) { _ in
                if isRecording && !isPaused {
                    recordingDuration += 1
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Waveform View
    
    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(0..<30) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.voiceitPurple.opacity(isRecording ? 0.7 : 0.3))
                    .frame(width: 3, height: CGFloat.random(in: 10...60))
                    .animation(.easeInOut(duration: 0.3).repeatForever(), value: isRecording)
            }
        }
        .frame(height: 60)
    }
    
    // MARK: - Control Buttons
    
    private var recordButton: some View {
        Button {
            startRecording()
        } label: {
            Image(systemName: "record.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(Color.voiceitError)
        }
    }
    
    private var pauseButton: some View {
        Button {
            isPaused.toggle()
        } label: {
            Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.voiceitPurple)
        }
    }
    
    private var stopButton: some View {
        Button {
            stopRecording()
        } label: {
            Image(systemName: "stop.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.voiceitError)
        }
    }
    
    // MARK: - Recording Controls
    
    private func startRecording() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                isRecording = true
                // Start actual recording here
            } else {
                errorMessage = "Microphone permission denied"
                showingError = true
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        isPaused = false
        // Stop actual recording here
    }
    
    private func saveRecording() {
        Task {
            do {
                // Get location if requested
                var locationSnapshot: LocationSnapshot?
                if includeLocation {
                    locationSnapshot = await locationService.createSnapshot()
                }
                
                // Create voice note
                let voiceNote = VoiceNote(
                    notes: notes,
                    locationSnapshot: locationSnapshot,
                    isCritical: isCritical,
                    audioFilePath: "placeholder", // Would be actual file path
                    duration: recordingDuration
                )
                
                modelContext.insert(voiceNote)
                try modelContext.save()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save recording: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    VoiceRecorderView()
}
