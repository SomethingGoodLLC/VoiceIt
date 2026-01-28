import SwiftUI

/// Screen showing all roadmap features with their vote counts and status
struct CommunityRoadmapView: View {
    @ObservedObject var store: RoadmapStore
    @Environment(\.dismiss) private var dismiss
    
    var groupedFeatures: [RoadmapFeature.FeatureCategory: [RoadmapFeature]] {
        Dictionary(grouping: store.features, by: { $0.category })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Summary stats
                    statsSection
                    
                    // Categories
                    LazyVStack(spacing: 32) {
                        ForEach(RoadmapFeature.FeatureCategory.allCases, id: \.self) { category in
                            if let features = groupedFeatures[category], !features.isEmpty {
                                categorySection(category: category, features: features)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.voiceitPurple)
                .accessibilityHidden(true)
            
            Text("Community Roadmap")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Help us decide what to build next. Your votes directly influence our development priorities.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }
    
    private var statsSection: some View {
        let totalInterested = store.features.reduce(0) { sum, feature in
            sum + store.getCounts(for: feature.id).interested
        }
        let votedCount = store.features.filter { store.hasVoted(on: $0.id) }.count
        
        return HStack(spacing: 20) {
            StatBadge(
                value: "\(totalInterested)",
                label: "Total Votes",
                icon: "heart.fill",
                color: .pink
            )
            
            StatBadge(
                value: "\(votedCount)/\(store.features.count)",
                label: "Your Votes",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
        .padding(.horizontal)
    }
    
    private func categorySection(category: RoadmapFeature.FeatureCategory, features: [RoadmapFeature]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                Text(category.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            
            ForEach(features) { feature in
                PreviewFeatureCard(feature: feature, store: store)
                    .padding(.horizontal)
            }
        }
    }
}

/// Small stat badge for the roadmap header
private struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    CommunityRoadmapView(store: RoadmapStore())
}
