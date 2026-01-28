import SwiftUI

/// Developer-only debug view to inspect captured roadmap analytics events
/// Access this view from Settings (behind a developer toggle)
struct DebugRoadmapEventsView: View {
    @State private var events: [RoadmapAnalytics.Event] = []
    @State private var showClearConfirmation = false
    
    var body: some View {
        List {
            Section {
                Text("Total Events: \(events.count)")
                    .font(.headline)
            }
            
            Section("Recent Events") {
                if events.isEmpty {
                    Text("No events captured yet")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(events.reversed()) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(event.action)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(colorForAction(event.action))
                                
                                Spacer()
                                
                                Text(event.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("Feature: \(event.featureId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("User: \(String(event.anonUserId.prefix(8)))...")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Roadmap Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(events.isEmpty)
            }
        }
        .alert("Clear All Events?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                RoadmapAnalytics.shared.clearEvents()
                events = []
            }
        } message: {
            Text("This will delete all captured roadmap analytics events.")
        }
        .onAppear {
            events = RoadmapAnalytics.shared.loadEvents()
        }
        .refreshable {
            events = RoadmapAnalytics.shared.loadEvents()
        }
    }
    
    private func colorForAction(_ action: String) -> Color {
        switch action {
        case "interested": return .green
        case "not_important": return .orange
        case "sponsor_lead": return .purple
        case "view_detail": return .blue
        default: return .primary
        }
    }
}

#Preview {
    NavigationStack {
        DebugRoadmapEventsView()
    }
}
