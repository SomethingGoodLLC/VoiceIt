import SwiftUI
import SwiftData

/// Main timeline view displaying all evidence chronologically
struct TimelineView: View {
    // MARK: - Properties
    
    @Query(sort: \VoiceNote.timestamp, order: .reverse) private var voiceNotes: [VoiceNote]
    @Query(sort: \PhotoEvidence.timestamp, order: .reverse) private var photos: [PhotoEvidence]
    @Query(sort: \VideoEvidence.timestamp, order: .reverse) private var videos: [VideoEvidence]
    @Query(sort: \TextEntry.timestamp, order: .reverse) private var textEntries: [TextEntry]
    
    @State private var searchText = ""
    @State private var filterType: EvidenceFilterType = .all
    @State private var showingFilterSheet = false
    
    @Environment(\.emergencyService) private var emergencyService
    @Environment(\.locationService) private var locationService
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Evidence list
                evidenceList
                
                // Emergency button
                emergencyButton
            }
            .navigationTitle("Timeline")
            .searchable(text: $searchText, prompt: "Search evidence")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(selectedFilter: $filterType)
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
                    ForEach(groupedEvidence.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(date.formatted(date: .complete, time: .omitted))) {
                            ForEach(groupedEvidence[date] ?? [], id: \.id) { evidence in
                                evidenceRow(for: evidence)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    @ViewBuilder
    private func evidenceRow(for evidence: any EvidenceProtocol) -> some View {
        if let voiceNote = evidence as? VoiceNote {
            EvidenceRowView(evidence: voiceNote)
        } else if let photo = evidence as? PhotoEvidence {
            EvidenceRowView(evidence: photo)
        } else if let video = evidence as? VideoEvidence {
            EvidenceRowView(evidence: video)
        } else if let text = evidence as? TextEntry {
            EvidenceRowView(evidence: text)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView(
            "No Evidence Yet",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Add your first piece of evidence using the + tab")
        )
    }
    
    // MARK: - Emergency Button
    
    private var emergencyButton: some View {
        Button {
            emergencyService.call911()
        } label: {
            Image(systemName: "phone.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(LinearGradient.emergency)
                        .frame(width: 70, height: 70)
                )
                .shadow(color: .red.opacity(0.5), radius: 10)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var allEvidence: [any EvidenceProtocol] {
        var all: [any EvidenceProtocol] = []
        all.append(contentsOf: voiceNotes)
        all.append(contentsOf: photos)
        all.append(contentsOf: videos)
        all.append(contentsOf: textEntries)
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
        
        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { evidence in
                evidence.notes.localizedCaseInsensitiveContains(searchText) ||
                evidence.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return results
    }
    
    private var groupedEvidence: [Date: [any EvidenceProtocol]] {
        Dictionary(grouping: filteredEvidence) { evidence in
            Calendar.current.startOfDay(for: evidence.timestamp)
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