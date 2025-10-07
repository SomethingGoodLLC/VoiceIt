import SwiftUI
import SwiftData

/// Detailed view for any evidence type with expandable preview and change history
struct EvidenceDetailView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let evidence: any EvidenceProtocol
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var loadedImage: UIImage?
    @State private var isLoadingImage = false
    @State private var imageError: String?
    
    // Services
    private let fileStorageService: FileStorageService
    
    // MARK: - Initialization
    
    init(evidence: any EvidenceProtocol, fileStorageService: FileStorageService) {
        self.evidence = evidence
        self.fileStorageService = fileStorageService
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with icon and title
                headerSection
                
                // Type-specific content preview
                contentPreview
                
                // Metadata section
                metadataSection
                
                // Change history (if available)
                if let textEntry = evidence as? TextEntry {
                    ChangeHistoryView(changeHistory: textEntry.changeHistory)
                } else if let photo = evidence as? PhotoEvidence {
                    ChangeHistoryView(changeHistory: photo.changeHistory)
                } else if let voiceNote = evidence as? VoiceNote {
                    ChangeHistoryView(changeHistory: voiceNote.changeHistory)
                } else if let video = evidence as? VideoEvidence {
                    ChangeHistoryView(changeHistory: video.changeHistory)
                }
                
                // Location information
                if let location = evidence.locationSnapshot {
                    locationSection(location: location)
                }
                
                // Tags
                if !evidence.tags.isEmpty {
                    tagsSection
                }
            }
            .padding()
        }
        .navigationTitle("Evidence Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if evidence is TextEntry {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let textEntry = evidence as? TextEntry {
                EditTextEntrySheet(textEntry: textEntry)
            }
        }
        .alert("Delete Evidence?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEvidence()
            }
        } message: {
            Text("This action cannot be undone. The evidence will be permanently deleted.")
        }
        .task {
            if let photo = evidence as? PhotoEvidence {
                await loadImage(for: photo)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: evidence.displayIcon)
                .font(.largeTitle)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.voiceitPurple)
                )
                .shadow(color: Color.voiceitPurple.opacity(0.3), radius: 8, y: 4)
            
            // Title and timestamp
            VStack(alignment: .leading, spacing: 6) {
                Text(evidence.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(evidence.timestamp.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if evidence.isCritical {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Critical Evidence")
                    }
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )
                }
            }
        }
    }
    
    // MARK: - Content Preview
    
    @ViewBuilder
    private var contentPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)
            
            if let textEntry = evidence as? TextEntry {
                textPreview(for: textEntry)
            } else if let photo = evidence as? PhotoEvidence {
                photoPreview(for: photo)
            } else if let voiceNote = evidence as? VoiceNote {
                voiceNotePreview(for: voiceNote)
            } else if let video = evidence as? VideoEvidence {
                videoPreview(for: video)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
        )
    }
    
    // MARK: - Text Preview
    
    private func textPreview(for textEntry: TextEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(textEntry.bodyText)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            
            HStack {
                Label("\(textEntry.wordCount) words", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label("~\(textEntry.estimatedReadingTime) min read", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Photo Preview
    
    private func photoPreview(for photo: PhotoEvidence) -> some View {
        VStack(spacing: 12) {
            if isLoadingImage {
                ProgressView("Loading image...")
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            } else if let error = imageError {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
            } else if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
            }
            
            HStack {
                Label("\(photo.width)×\(photo.height)", systemImage: "viewfinder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(photo.formattedFileSize, systemImage: "doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Voice Note Preview
    private func voiceNotePreview(for voiceNote: VoiceNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Audio info
            HStack {
                Image(systemName: "waveform")
                    .font(.title)
                    .foregroundStyle(Color.voiceitPurple)
                
                VStack(alignment: .leading) {
                    Text("Audio Recording")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(voiceNote.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            
            // Transcription
            if let transcription = voiceNote.transcription {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcription")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(transcription)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
    }
    
    // MARK: - Video Preview
    
    private func videoPreview(for video: VideoEvidence) -> some View {
        VStack(spacing: 12) {
            // Video placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 250)
                
                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.voiceitPurple)
                    
                    Text("Video: \(video.formattedDuration)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Label(video.resolution, systemImage: "viewfinder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(video.formattedFileSize, systemImage: "doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                metadataRow(label: "Created", value: evidence.timestamp.formatted(date: .long, time: .complete))
                metadataRow(label: "ID", value: evidence.id.uuidString)
                metadataRow(label: "Encrypted", value: evidence.isEncrypted ? "Yes" : "No")
                
                if !evidence.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(evidence.notes)
                            .font(.body)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Location Section
    
    private func locationSection(location: LocationSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color.voiceitPurple)
                Text("Location")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if !location.fullAddress.isEmpty {
                    Text(location.fullAddress)
                        .font(.body)
                }
                
                Text(location.coordinatesString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Accuracy: ±\(Int(location.horizontalAccuracy))m (\(location.accuracyQuality.rawValue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let altitude = location.altitude, altitude != 0 {
                    Text("Altitude: \(Int(altitude))m above sea level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(evidence.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.voiceitPurple.opacity(0.1))
                        )
                        .foregroundStyle(Color.voiceitPurple)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Actions
    
    private func loadImage(for photo: PhotoEvidence) async {
        isLoadingImage = true
        imageError = nil
        
        do {
            let image = try await fileStorageService.loadImage(photo.imageFilePath)
            await MainActor.run {
                loadedImage = image
                isLoadingImage = false
            }
        } catch {
            await MainActor.run {
                imageError = "Failed to load image: \(error.localizedDescription)"
                isLoadingImage = false
            }
        }
    }
    
    private func deleteEvidence() {
        if let voiceNote = evidence as? VoiceNote {
            modelContext.delete(voiceNote)
        } else if let photo = evidence as? PhotoEvidence {
            modelContext.delete(photo)
        } else if let video = evidence as? VideoEvidence {
            modelContext.delete(video)
        } else if let text = evidence as? TextEntry {
            modelContext.delete(text)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    NavigationStack {
        EvidenceDetailView(
            evidence: TextEntry(
                bodyText: "This is a sample text entry with some content to display in the detail view.",
                isQuickNote: false
            ),
            fileStorageService: FileStorageService(encryptionService: EncryptionService())
        )
    }
    .modelContainer(for: [TextEntry.self], inMemory: true)
}
