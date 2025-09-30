import SwiftUI

/// Main "Add Evidence" tab with centered action button
struct AddEvidenceView: View {
    // MARK: - Properties
    
    @State private var showingActionSheet = false
    @State private var selectedType: EvidenceType?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                Color.voiceitGradient
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Title Section
                    VStack(spacing: 12) {
                        Text("Document Evidence")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Tap the button below to add evidence")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 60)
                    
                    Spacer()
                    
                    // Large Centered + Button
                    Button {
                        showingActionSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 140, height: 140)
                                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(Color.voiceitPurple)
                        }
                    }
                    .scaleEffect(showingActionSheet ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingActionSheet)
                    
                    Spacer()
                    
                    // Tip Section
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text("All evidence is encrypted and stored securely on your device")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)
                }
            }
            .confirmationDialog("Add Evidence", isPresented: $showingActionSheet, titleVisibility: .visible) {
                Button {
                    selectedType = .voiceNote
                } label: {
                    Label("Voice Note", systemImage: "mic.circle.fill")
                }
                
                Button {
                    selectedType = .photo
                } label: {
                    Label("Photo", systemImage: "camera.circle.fill")
                }
                
                Button {
                    selectedType = .video
                } label: {
                    Label("Video", systemImage: "video.circle.fill")
                }
                
                Button {
                    selectedType = .text
                } label: {
                    Label("Text Entry", systemImage: "doc.text.fill")
                }
                
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose the type of evidence to document")
            }
            .sheet(item: $selectedType) { type in
                destinationView(for: type)
            }
        }
    }
    
    // MARK: - Destination View
    
    @ViewBuilder
    private func destinationView(for type: EvidenceType) -> some View {
        switch type {
        case .voiceNote:
            VoiceRecorderView()
        case .photo:
            PhotoCaptureView()
        case .video:
            VideoCaptureView()
        case .text:
            TextEntryView()
        }
    }
}

// MARK: - Evidence Type

enum EvidenceType: Identifiable {
    case voiceNote
    case photo
    case video
    case text
    
    var id: String {
        switch self {
        case .voiceNote:
            return "voice"
        case .photo:
            return "photo"
        case .video:
            return "video"
        case .text:
            return "text"
        }
    }
    
    var title: String {
        switch self {
        case .voiceNote:
            return "Voice Note"
        case .photo:
            return "Photo"
        case .video:
            return "Video"
        case .text:
            return "Text Note"
        }
    }
    
    var icon: String {
        switch self {
        case .voiceNote:
            return "mic.circle.fill"
        case .photo:
            return "camera.circle.fill"
        case .video:
            return "video.circle.fill"
        case .text:
            return "doc.text.fill"
        }
    }
    
    var description: String {
        switch self {
        case .voiceNote:
            return "Record what happened"
        case .photo:
            return "Take or upload photo"
        case .video:
            return "Record video evidence"
        case .text:
            return "Write it down"
        }
    }
}

#Preview {
    AddEvidenceView()
}