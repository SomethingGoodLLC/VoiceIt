import SwiftUI
import SwiftData

/// Main timeline view displaying all evidence chronologically with modern SwiftUI patterns
struct TimelineView: View {
    // MARK: - Properties
    
    // Direct SwiftData queries (sorted by timestamp descending for performance)
    @Query(sort: \VoiceNote.timestamp, order: .reverse) private var voiceNotes: [VoiceNote]
    @Query(sort: \PhotoEvidence.timestamp, order: .reverse) private var photos: [PhotoEvidence]
    @Query(sort: \VideoEvidence.timestamp, order: .reverse) private var videos: [VideoEvidence]
    @Query(sort: \TextEntry.timestamp, order: .reverse) private var textEntries: [TextEntry]
    
    @Environment(\.modelContext) private var modelContext
    
    // Services
    private let fileStorageService: FileStorageService
    
    // MARK: - Initialization
    
    init() {
        // Initialize services
        let encryptionService = EncryptionService()
        self.fileStorageService = FileStorageService(encryptionService: encryptionService)
    }
    
    // State
    @State private var filterType: EvidenceFilterType = .all
    @State private var showingFilterSheet = false
    @State private var stealthMode = false
    @State private var isRefreshing = false
    @State private var showingExportSheet = false
    @State private var itemToDelete: (any EvidenceProtocol)?
    @State private var showingDeleteConfirmation = false
    @State private var itemToShare: (any EvidenceProtocol)?
    @State private var showingShareSheet = false
    @State private var expandedPhotoId: UUID?
    @State private var loadedImages: [UUID: UIImage] = [:]
    @State private var loadingImageIds: Set<UUID> = []
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if stealthMode {
                    // Decoy screen (Calculator UI)
                    decoyScreen
                } else {
                    // Real timeline content
                    VStack(spacing: 0) {
                        // Evidence list with pull-to-refresh
                        evidenceList
                        
                        // Bottom sticky banner
                        exportBanner
                    }
                }
            }
            .navigationTitle("Evidence Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Stealth mode toggle
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            stealthMode.toggle()
                        }
                    } label: {
                        Label("Stealth Mode", systemImage: stealthMode ? "eye.slash.fill" : "eye.fill")
                            .symbolEffect(.bounce, value: stealthMode)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    // Filter menu
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(selectedFilter: $filterType)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportOptionsSheet(evidence: filteredEvidence)
                    .presentationDetents([.medium, .large])
            }
            .alert("Delete Evidence?", isPresented: $showingDeleteConfirmation, presenting: itemToDelete) { item in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteEvidence(item)
                }
            } message: { item in
                Text("This action cannot be undone. The evidence '\(item.displayTitle)' will be permanently deleted.")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                // Shake gesture to exit stealth mode
                if stealthMode {
                    withAnimation(.spring(response: 0.3)) {
                        stealthMode = false
                    }
                }
            }
        }
    }
    
    // MARK: - Evidence List
    
    private var evidenceList: some View {
        Group {
            if allEvidence.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredEvidence, id: \.id) { evidence in
                        VStack(spacing: 0) {
                            // Check if this is a photo evidence
                            if let photo = evidence as? PhotoEvidence {
                                // Photo evidence - expandable inline
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        if expandedPhotoId == photo.id {
                                            expandedPhotoId = nil
                                        } else {
                                            expandedPhotoId = photo.id
                                            loadPhotoIfNeeded(photo)
                                        }
                                    }
                                } label: {
                                    // Remove rounded background so the preview sits closer
                                    timelineRowHeader(for: evidence)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Expanded photo preview
                                if expandedPhotoId == photo.id {
                                    photoPreviewPane(for: photo)
                                        .padding(.horizontal, 16) // Minimal horizontal padding
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                            } else {
                                // Other evidence types - navigate to detail view
                                NavigationLink {
                                    EvidenceDetailView(evidence: evidence, fileStorageService: fileStorageService)
                                } label: {
                                    timelineRow(for: evidence)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .listRowInsets(EdgeInsets(
                            top: 6,
                            leading: 0,
                            bottom: 0,
                            trailing: 16
                        ))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Delete action
                            Button(role: .destructive) {
                                itemToDelete = evidence
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            
                            // Share action
                            Button {
                                itemToShare = evidence
                                showingShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await refresh()
                }
            }
        }
    }
    
    // MARK: - Timeline Row with Purple Accent Bar
    
    // Header-only (no background) for reuse
    private func timelineRowHeader(for evidence: any EvidenceProtocol) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Purple vertical accent bar
            // Align all purple bars using a fixed leading inset
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.voiceitPurple)
                .frame(width: 4)
                .padding(.leading, 16) // single source of truth for bar alignment
            
            // Content
            HStack(alignment: .top, spacing: 10) {
                // SF Symbol badge
                Image(systemName: evidence.displayIcon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.voiceitPurple)
                    )
                    .shadow(color: Color.voiceitPurple.opacity(0.3), radius: 4, y: 2)
                
                // Evidence details
                VStack(alignment: .leading, spacing: (evidence is PhotoEvidence) ? 3 : 6) {
                    // Title and critical badge
                    HStack(alignment: .top) {
                        Text(evidence.displayTitle)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                        
                        if evidence.isCritical {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(Color.voiceitCritical)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    
                    // Relative timestamp
                    Text(evidence.timestamp.relativeTime)
                        .font((evidence is PhotoEvidence) ? .caption : .subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Preview text (omit for photos to keep row compact)
                    if !(evidence is PhotoEvidence) && !evidence.notes.isEmpty {
                        Text(evidence.notes)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                    
                    // Type-specific preview (omit for photos for tighter spacing)
                    if !(evidence is PhotoEvidence) {
                        typeSpecificPreview(for: evidence)
                    }
                    
                    // Location badge
                    if let location = evidence.locationSnapshot {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(location.shortAddress.isEmpty ? "Location recorded" : location.shortAddress)
                                .font(.caption)
                        }
                        .foregroundStyle(Color.voiceitPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.voiceitPurple.opacity(0.1))
                        .clipShape(Capsule())
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 10)
            .padding(.top, 8)
            .padding(.bottom, evidence is PhotoEvidence ? 0 : 8)
        }
    }
    
    @ViewBuilder
    private func timelineRow(for evidence: any EvidenceProtocol) -> some View {
        timelineRowHeader(for: evidence)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
            )
            .padding(.horizontal, 4)
    }
    
    // MARK: - Photo Preview Pane
    
    @ViewBuilder
    private func photoPreviewPane(for photo: PhotoEvidence) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image preview - no spacing at all
            if loadingImageIds.contains(photo.id) {
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading photo...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 80)
                    Spacer()
                }
            } else if let image = loadedImages[photo.id] {
                VStack(spacing: 0) {
                    // Full image - larger display
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                    
                    // Image metadata
                    HStack(spacing: 6) {
                        Label("\(photo.width)×\(photo.height)", systemImage: "viewfinder")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Label(photo.formattedFileSize, systemImage: "doc")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        if photo.hasMetadata {
                            Label("Metadata", systemImage: "info.circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    // Notes if available
                    if !photo.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Notes")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text(photo.notes)
                                .font(.caption)
                                .lineLimit(2)
                                .padding(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray6))
                                )
                        }
                        .padding(.top, 4)
                    }
                    
                    // View full details button
                    NavigationLink {
                        EvidenceDetailView(evidence: photo, fileStorageService: fileStorageService)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle")
                            Text("View Full Details")
                                .fontWeight(.medium)
                        }
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.voiceitPurple)
                        )
                    }
                    .padding(.top, 4)
                }
            } else {
                // Error state
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title3)
                            .foregroundStyle(.red)
                        Text("Failed to load image")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            loadPhotoIfNeeded(photo)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.voiceitPurple)
                    }
                    .frame(height: 100)
                    Spacer()
                }
            }
        }
        .padding(.top, 0)
        .padding(.leading, 0)
        .padding(.trailing, 0)
    }
    
    // MARK: - Type-Specific Preview
    
    @ViewBuilder
    private func typeSpecificPreview(for evidence: any EvidenceProtocol) -> some View {
        HStack(spacing: 6) {
            if let voiceNote = evidence as? VoiceNote {
                Image(systemName: "waveform")
                    .font(.caption2)
                Text(voiceNote.formattedDuration)
                    .font(.caption)
                if voiceNote.transcription != nil {
                    Image(systemName: "text.bubble.fill")
                        .font(.caption2)
                }
            } else if let photo = evidence as? PhotoEvidence {
                Image(systemName: "photo.fill")
                    .font(.caption2)
                Text("\(photo.width)×\(photo.height)")
                    .font(.caption)
            } else if let video = evidence as? VideoEvidence {
                Image(systemName: "film.fill")
                    .font(.caption2)
                Text(video.formattedDuration)
                    .font(.caption)
            } else if let text = evidence as? TextEntry {
                Image(systemName: "doc.text.fill")
                    .font(.caption2)
                Text("\(text.wordCount) words")
                    .font(.caption)
            }
        }
        .foregroundStyle(.tertiary)
        .padding(.top, 2)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No evidence yet", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("Tap + to start documenting.")
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Export Banner
    
    private var exportBanner: some View {
        Button {
            showingExportSheet = true
        } label: {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timeline ready for legal export")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("\(filteredEvidence.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.doc.fill")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.voiceitPurple, Color.voiceitPurpleLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .disabled(filteredEvidence.isEmpty)
        .opacity(filteredEvidence.isEmpty ? 0.6 : 1)
    }
    
    // MARK: - Decoy Screen (Stealth Mode)
    
    private var decoyScreen: some View {
        VStack {
            Text("Calculator")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            Spacer()
            
            // Simple calculator display
            VStack(spacing: 1) {
                HStack {
                    Spacer()
                    Text("0")
                        .font(.system(size: 60, weight: .light))
                        .padding()
                }
                .background(Color(.systemGray6))
                
                // Calculator button grid
                VStack(spacing: 1) {
                    ForEach(0..<4) { row in
                        HStack(spacing: 1) {
                            ForEach(0..<4) { col in
                                Color(.systemGray5)
                                    .frame(height: 80)
                                    .overlay(
                                        Text(calculatorButton(row: row, col: col))
                                            .font(.title)
                                    )
                            }
                        }
                    }
                }
            }
            .cornerRadius(12)
            .padding()
            
            Text("Shake device to exit")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
    }
    
    private func calculatorButton(row: Int, col: Int) -> String {
        let buttons = [
            ["C", "±", "%", "÷"],
            ["7", "8", "9", "×"],
            ["4", "5", "6", "-"],
            ["1", "2", "3", "+"]
        ]
        return buttons[row][col]
    }
    
    // MARK: - Computed Properties
    
    private var allEvidence: [any EvidenceProtocol] {
        var all: [any EvidenceProtocol] = []
        all.append(contentsOf: voiceNotes)
        all.append(contentsOf: photos)
        all.append(contentsOf: videos)
        all.append(contentsOf: textEntries)
        // Already sorted by @Query, just combine
        return all.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var filteredEvidence: [any EvidenceProtocol] {
        var results = allEvidence
        
        // Filter by type
        if filterType != .all {
            results = results.filter { evidence in
                switch filterType {
                case .voiceNotes:
                    return evidence is VoiceNote
                case .photos:
                    return evidence is PhotoEvidence
                case .videos:
                    return evidence is VideoEvidence
                case .text:
                    return evidence is TextEntry
                case .critical:
                    return evidence.isCritical
                case .all:
                    return true
                }
            }
        }
        
        return results
    }
    
    // MARK: - Actions
    
    private func refresh() async {
        isRefreshing = true
        // Small delay for visual feedback
        try? await Task.sleep(for: .milliseconds(500))
        isRefreshing = false
    }
    
    private func loadPhotoIfNeeded(_ photo: PhotoEvidence) {
        // Don't reload if already loaded
        guard loadedImages[photo.id] == nil else { return }
        
        // Don't load if already loading
        guard !loadingImageIds.contains(photo.id) else { return }
        
        loadingImageIds.insert(photo.id)
        
        Task {
            do {
                let image = try await fileStorageService.loadImage(photo.imageFilePath)
                await MainActor.run {
                    loadedImages[photo.id] = image
                    loadingImageIds.remove(photo.id)
                }
            } catch {
                print("❌ Failed to load image: \(error.localizedDescription)")
                await MainActor.run {
                    loadingImageIds.remove(photo.id)
                }
            }
        }
    }
    
    private func deleteEvidence(_ evidence: any EvidenceProtocol) {
        withAnimation {
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
        }
    }
}

// MARK: - Filter Types

enum EvidenceFilterType: String, CaseIterable {
    case all = "All"
    case voiceNotes = "Voice Notes"
    case photos = "Photos"
    case videos = "Videos"
    case text = "Text"
    case critical = "Critical"
    
    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .voiceNotes:
            return "mic.circle.fill"
        case .photos:
            return "camera.fill"
        case .videos:
            return "video.circle.fill"
        case .text:
            return "doc.text.fill"
        case .critical:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var selectedFilter: EvidenceFilterType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(EvidenceFilterType.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: filter.icon)
                            .foregroundStyle(selectedFilter == filter ? Color.voiceitPurple : Color.gray)
                        
                        Text(filter.rawValue)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.voiceitPurple)
                        }
                    }
                }
            }
            .navigationTitle("Filter Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: [VoiceNote.self, PhotoEvidence.self, VideoEvidence.self, TextEntry.self], inMemory: true)
}
