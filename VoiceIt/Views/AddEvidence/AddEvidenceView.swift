import SwiftUI

/// Evidence type selection view
struct AddEvidenceView: View {
    // MARK: - Properties
    
    @State private var selectedType: EvidenceType?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                Color.voiceitGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("Add Evidence")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Choose the type of evidence to document")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    // Evidence type buttons
                    VStack(spacing: 20) {
                        evidenceTypeButton(.voiceNote)
                        evidenceTypeButton(.photo)
                        evidenceTypeButton(.video)
                        evidenceTypeButton(.text)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .sheet(item: $selectedType) { type in
                destinationView(for: type)
            }
        }
    }
    
    // MARK: - Evidence Type Button
    
    private func evidenceTypeButton(_ type: EvidenceType) -> some View {
        Button {
            selectedType = type
        } label: {
            HStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.headline)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding()
            .background(.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
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
            PhotoCaptureView() // Will use camera for video
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
            return "Record audio with optional transcription"
        case .photo:
            return "Capture photos with metadata"
        case .video:
            return "Record video evidence"
        case .text:
            return "Write detailed notes"
        }
    }
}

#Preview {
    AddEvidenceView()
}
