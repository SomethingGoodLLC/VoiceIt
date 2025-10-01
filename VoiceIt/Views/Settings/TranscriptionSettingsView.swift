import SwiftUI

/// Comprehensive transcription settings view
struct TranscriptionSettingsView: View {
    // MARK: - Properties
    
    @State private var transcriptionService = TranscriptionService()
    @State private var showingModelDownload = false
    @State private var showingDownloadPrompt = false
    
    @AppStorage("autoTranscribeRecordings") private var autoTranscribe = true
    @AppStorage("processInBackground") private var processInBackground = true
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Mode Selection
            modeSection
            
            // Model Management
            if transcriptionService.mode == .whisper || transcriptionService.mode == .auto {
                modelSection
            }
            
            // Options
            optionsSection
            
            // Privacy Info
            privacySection
            
            // Statistics
            statisticsSection
        }
        .navigationTitle("Transcription")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingModelDownload) {
            ModelDownloadView(whisperService: transcriptionService.whisperModelService)
        }
        .alert("Download Whisper Model?", isPresented: $showingDownloadPrompt) {
            Button("Download Now") {
                showingModelDownload = true
            }
            Button("Maybe Later", role: .cancel) {}
        } message: {
            Text("You've selected '\(transcriptionService.mode.displayName)' but the offline Whisper model isn't downloaded yet. Download it now for 100% private transcription?")
        }
    }
    
    // MARK: - Mode Section
    
    private var modeSection: some View {
        Section {
            Picker("Transcription Mode", selection: $transcriptionService.mode) {
                ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: transcriptionService.mode) { oldValue, newValue in
                // Alert user if they select Whisper/Auto but model isn't downloaded
                if (newValue == .whisper || newValue == .auto) && !transcriptionService.isWhisperModelDownloaded {
                    showingDownloadPrompt = true
                }
            }
            
        } header: {
            Text("Transcription Mode")
        } footer: {
            modeFooterText
        }
    }
    
    private var modeFooterText: some View {
        Group {
            switch transcriptionService.mode {
            case .apple:
                Text("Uses Apple's Speech Recognition. May require internet connection for some languages.")
            case .whisper:
                if transcriptionService.isWhisperModelDownloaded {
                    Text("Uses offline Whisper model. Complete privacy - nothing leaves your device.")
                } else {
                    Text("Whisper model not downloaded. Download the model below to use offline transcription.")
                }
            case .auto:
                if transcriptionService.isWhisperModelDownloaded {
                    Text("Automatically uses Whisper when available, falls back to Apple Speech Recognition if needed.")
                } else {
                    Text("Currently using Apple Speech Recognition. Download Whisper model for offline transcription.")
                }
            }
        }
    }
    
    // MARK: - Model Section
    
    private var modelSection: some View {
        Section {
            if transcriptionService.isWhisperModelDownloaded {
                // Model is downloaded
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offline Model Installed")
                            .font(.subheadline)
                        
                        Text("Using \(transcriptionService.whisperModelSize.formattedFileSize)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showingModelDownload = true
                    } label: {
                        Text("Manage")
                            .font(.subheadline)
                    }
                }
            } else {
                // Model not downloaded
                Button {
                    showingModelDownload = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(Color.voiceitPurple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Download Offline Model")
                                .font(.subheadline)
                            
                            Text("~500 MB required")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
            
        } header: {
            Text("Offline Model")
        } footer: {
            Text("Download the Whisper model for 100% offline transcription. Works without internet and keeps your recordings completely private.")
        }
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        Section {
            Toggle(isOn: $autoTranscribe) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-transcribe recordings")
                        .font(.subheadline)
                    
                    Text("Transcribe voice notes automatically after recording")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Toggle(isOn: $processInBackground) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Process in background")
                        .font(.subheadline)
                    
                    Text("Continue using the app while transcribing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
        } header: {
            Text("Processing Options")
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(Color.voiceitPurple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy Guarantee")
                        .font(.subheadline.bold())
                    
                    Text("All offline transcriptions stay on your device. No data is ever uploaded to servers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            
        } header: {
            Text("Privacy")
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        Section {
            HStack {
                Label("Current Method", systemImage: "waveform")
                Spacer()
                HStack(spacing: 4) {
                    Text(transcriptionService.lastUsedMethod.badge)
                    Text(transcriptionService.lastUsedMethod.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if transcriptionService.isWhisperModelDownloaded {
                HStack {
                    Label("Offline Ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text("Yes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Label("Offline Ready", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Spacer()
                    Text("No (Download model)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
        } header: {
            Text("Status")
        }
    }
}

#Preview {
    NavigationStack {
        TranscriptionSettingsView()
    }
}

