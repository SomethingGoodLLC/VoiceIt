import SwiftUI

/// Row view for displaying evidence in timeline
struct EvidenceRowView<T: EvidenceProtocol>: View {
    // MARK: - Properties
    
    let evidence: T
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon
            Image(systemName: evidence.displayIcon)
                .font(.title2)
                .foregroundStyle(Color.voiceitPurple)
                .frame(width: 40, height: 40)
                .background(Color.voiceitPurple.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title and critical badge
                HStack {
                    Text(evidence.displayTitle)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if evidence.isCritical {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.voiceitError)
                            .font(.caption)
                    }
                }
                
                // Time
                Text(evidence.timestamp.smartFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Notes preview
                if !evidence.notes.isEmpty {
                    Text(evidence.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Location badge
                if let location = evidence.locationSnapshot {
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location.shortAddress.isEmpty ? "Location recorded" : location.shortAddress)
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.voiceitPurple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.voiceitPurple.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                // Tags
                if !evidence.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(evidence.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Type-specific details
                typeSpecificDetails
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Type-Specific Details
    
    @ViewBuilder
    private var typeSpecificDetails: some View {
        if let voiceNote = evidence as? VoiceNote {
            HStack(spacing: 5) {
                Image(systemName: "waveform")
                    .font(.caption2)
                Text(voiceNote.formattedDuration)
                    .font(.caption2)
                if let _ = voiceNote.transcription {
                    Image(systemName: "text.bubble")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
        } else if let photo = evidence as? PhotoEvidence {
            HStack(spacing: 5) {
                Image(systemName: "photo")
                    .font(.caption2)
                Text("\(photo.width)×\(photo.height)")
                    .font(.caption2)
                Text(photo.formattedFileSize)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        } else if let video = evidence as? VideoEvidence {
            HStack(spacing: 5) {
                Image(systemName: "film")
                    .font(.caption2)
                Text(video.formattedDuration)
                    .font(.caption2)
                Text(video.formattedFileSize)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        } else if let textEntry = evidence as? TextEntry {
            HStack(spacing: 5) {
                Image(systemName: "doc.text")
                    .font(.caption2)
                Text("\(textEntry.wordCount) words")
                    .font(.caption2)
                Text("~\(textEntry.estimatedReadingTime) min read")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        EvidenceRowView(evidence: TextEntry(
            bodyText: "This is a test text entry with some content",
            isQuickNote: false
        ))
        
        EvidenceRowView(evidence: VoiceNote(
            audioFilePath: "/path/to/audio",
            duration: 125,
            transcription: "Test transcription"
        ))
    }
}
