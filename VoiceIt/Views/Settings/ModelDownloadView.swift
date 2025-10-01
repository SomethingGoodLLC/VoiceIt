import SwiftUI

/// Dedicated view for downloading and managing the Whisper offline transcription model
struct ModelDownloadView: View {
    // MARK: - Properties
    
    var whisperService: WhisperModelService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Section
                    heroSection
                    
                    // Benefits
                    benefitsSection
                    
                    // Requirements
                    requirementsSection
                    
                    // Action Button
                    actionSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.voiceitPurple.opacity(0.1), Color.pink.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Offline Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Model", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteModel()
                }
            } message: {
                Text("This will delete the offline transcription model and free up \(whisperService.modelSize.formattedFileSize). You can re-download it anytime.")
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.voiceitPurple, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            
            Text("100% Offline Transcription")
                .font(.title.bold())
            
            Text("Your voice never leaves your device")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.top)
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Benefits")
                .font(.headline)
            
            BenefitRow(
                icon: "lock.fill",
                title: "Complete privacy",
                description: "No internet required"
            )
            
            BenefitRow(
                icon: "antenna.radiowaves.left.and.right.slash",
                title: "Works anywhere",
                description: "Even without signal"
            )
            
            BenefitRow(
                icon: "bolt.fill",
                title: "Faster processing",
                description: "On newer iPhones"
            )
            
            BenefitRow(
                icon: "globe",
                title: "Supports 90+ languages",
                description: "Multilingual transcription"
            )
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Requirements Section
    
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Requirements")
                .font(.headline)
            
            HStack(spacing: 12) {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(Color.voiceitPurple)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storage needed: 482 MB")
                        .font(.subheadline)
                    
                    Text("Available: \(availableStorage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "iphone")
                    .foregroundStyle(Color.voiceitPurple)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iPhone 12 or newer recommended")
                        .font(.subheadline)
                    
                    Text("Works best with Neural Engine")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "wifi")
                    .foregroundStyle(Color.voiceitPurple)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("WiFi recommended for download")
                        .font(.subheadline)
                    
                    Text("~500 MB download")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            if whisperService.isDownloading {
                downloadingView
            } else if whisperService.isModelDownloaded {
                downloadedView
            } else {
                downloadButton
            }
        }
    }
    
    private var downloadButton: some View {
        Button {
            startDownload()
        } label: {
            Label("Download Offline Model", systemImage: "arrow.down.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.voiceitPurple)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        }
    }
    
    private var downloadingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: whisperService.downloadProgress) {
                HStack {
                    Text("Downloading...")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(Int(whisperService.downloadProgress * 100))%")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                
                Text("This may take a few minutes. You can use the app while downloading.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    private var downloadedView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model Installed")
                        .font(.headline)
                    
                    Text("Using \(whisperService.modelSize.formattedFileSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Model", systemImage: "trash.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }
        }
    }
    
    // MARK: - Helpers
    
    private var availableStorage: String {
        if let attributes = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ),
        let freeSize = attributes[.systemFreeSize] as? Int64 {
            return freeSize.formattedFileSize
        }
        return "Unknown"
    }
    
    private func startDownload() {
        Task {
            do {
                try await whisperService.downloadModel()
                
                // Success haptic
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                
                // Error haptic
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
    
    private func deleteModel() {
        do {
            try whisperService.deleteModel()
            
            // Success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            
            // Error haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.voiceitPurple)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Extensions

extension Int64 {
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

#Preview {
    ModelDownloadView(whisperService: WhisperModelService())
}

