import SwiftUI

/// First-time transcription setup view with clear options and recommendations
struct TranscriptionSetupView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @State private var transcriptionService = TranscriptionService()
    @State private var selectedOption: TranscriptionOption = .whisper
    @State private var showingModelDownload = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding()
                
                // Options
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Whisper - Recommended
                            OptionCard(
                                option: .whisper,
                                isSelected: selectedOption == .whisper,
                                isRecommended: true
                            ) {
                                selectedOption = .whisper
                            }
                            
                            // Apple Speech
                            OptionCard(
                                option: .apple,
                                isSelected: selectedOption == .apple,
                                isRecommended: false
                            ) {
                                selectedOption = .apple
                            }
                            
                            // None
                            OptionCard(
                                option: .none,
                                isSelected: selectedOption == .none,
                                isRecommended: false
                            ) {
                                selectedOption = .none
                            }
                        }
                        .padding()
                        .padding(.bottom, 60) // Extra padding for gradient visibility
                    }
                    
                    // Scroll hint gradient
                    LinearGradient(
                        colors: [
                            Color(uiColor: .systemGroupedBackground).opacity(0),
                            Color(uiColor: .systemGroupedBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .allowsHitTesting(false)
                }
                
                // Continue Button
                continueButton
                    .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Voice Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        // Default to no transcription if they skip
                        saveChoice(.none)
                    }
                }
            }
            .sheet(isPresented: $showingModelDownload) {
                ModelDownloadView(whisperService: transcriptionService.whisperModelService)
                    .onDisappear {
                        // Give the system a moment to finish writing files
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            
                            await MainActor.run {
                                // When model download sheet closes, complete setup
                                transcriptionService.mode = .auto
                                print("✅ ModelDownload closed - Setting transcriptionSetupCompleted = true")
                                UserDefaults.standard.set(true, forKey: "transcriptionSetupCompleted")
                                dismiss()
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.voiceitPurple, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Voice Note Transcription")
                .font(.title2.bold())
            
            Text("Choose how to convert your voice notes to text")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Options indicator
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.voiceitPurple.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button {
            handleContinue()
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.voiceitPurple)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        }
    }
    
    // MARK: - Actions
    
    private func handleContinue() {
        if selectedOption == .whisper {
            // Show download screen for Whisper
            showingModelDownload = true
        } else {
            saveChoice(selectedOption)
        }
    }
    
    private func saveChoice(_ option: TranscriptionOption) {
        // Save the user's choice
        switch option {
        case .whisper:
            transcriptionService.mode = .auto // Auto will use Whisper when available
        case .apple:
            transcriptionService.mode = .apple
        case .none:
            // Disable auto-transcribe
            UserDefaults.standard.set(false, forKey: "autoTranscribeRecordings")
        }
        
        // Mark setup as complete
        print("✅ TranscriptionSetup - Setting transcriptionSetupCompleted = true")
        UserDefaults.standard.set(true, forKey: "transcriptionSetupCompleted")
        
        dismiss()
    }
}

// MARK: - Transcription Option

enum TranscriptionOption {
    case whisper
    case apple
    case none
    
    var title: String {
        switch self {
        case .whisper: return "Offline Whisper"
        case .apple: return "Apple Speech Recognition"
        case .none: return "No Transcription"
        }
    }
    
    var icon: String {
        switch self {
        case .whisper: return "lock.shield.fill"
        case .apple: return "cloud.fill"
        case .none: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .whisper: return .green
        case .apple: return .blue
        case .none: return .gray
        }
    }
    
    var benefits: [String] {
        switch self {
        case .whisper:
            return [
                "100% offline - nothing leaves your device",
                "Complete privacy for sensitive recordings",
                "Works anywhere without internet",
                "Supports 90+ languages"
            ]
        case .apple:
            return [
                "Built into iOS - no download needed",
                "Apple doesn't store your recordings",
                "May require internet for some languages",
                "Fast and reliable"
            ]
        case .none:
            return [
                "Audio-only recordings",
                "Smallest file sizes",
                "Can add transcriptions later",
                "Manual note-taking only"
            ]
        }
    }
    
    var requirements: String? {
        switch self {
        case .whisper:
            return "Requires ~500 MB storage"
        case .apple:
            return "No additional storage needed"
        case .none:
            return nil
        }
    }
}

// MARK: - Option Card

struct OptionCard: View {
    let option: TranscriptionOption
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and title
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(option.color.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: option.icon)
                            .font(.title2)
                            .foregroundStyle(option.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(option.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            if isRecommended {
                                Text("✓ Best")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        if let requirements = option.requirements {
                            Text(requirements)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color.voiceitPurple : .secondary)
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(option.benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10))
                                .foregroundStyle(option.color)
                                .frame(width: 12)
                            
                            Text(benefit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .stroke(isSelected ? Color.voiceitPurple : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.voiceitPurple.opacity(0.3) : Color.clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TranscriptionSetupView()
}

