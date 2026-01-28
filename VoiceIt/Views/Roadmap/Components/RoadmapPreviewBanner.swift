import SwiftUI

/// A specialized banner for feature pages that are in preview
/// Includes voting actions directly in the banner
struct RoadmapPreviewBanner: View {
    let featureId: String
    @EnvironmentObject var roadmapStore: RoadmapStore
    @State private var showSponsorSheet = false
    @State private var showDirectSponsorForm = false
    
    var feature: RoadmapFeature? {
        roadmapStore.features.first(where: { $0.id == featureId })
    }
    
    var hasVoted: Bool {
        guard let feature = feature else { return false }
        return roadmapStore.hasVoted(on: feature.id)
    }
    
    var voteCounts: RoadmapStore.VoteCounts {
        guard let feature = feature else { return RoadmapStore.VoteCounts(interested: 0, skipped: 0) }
        return roadmapStore.getCounts(for: feature.id)
    }
    
    var body: some View {
        if let feature = feature {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.voiceitPurple)
                            Text("Preview Feature")
                                .font(.headline)
                                .foregroundStyle(Color.voiceitPurple)
                        }
                        
                        Text("This interface is a preview of what we're building.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    if feature.isFundingTarget {
                        Button {
                            showDirectSponsorForm = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Needs Sponsor")
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .accessibilityLabel("Needs Sponsor. Tap to refer a potential sponsor.")
                        .accessibilityHint("Double tap to open referral form")
                    }
                }
                
                if hasVoted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("You voted for this feature")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                        
                        Spacer()
                        
                        Text("\(voteCounts.interested) votes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button {
                            roadmapStore.vote(featureId: feature.id, type: .skipped)
                        } label: {
                            Text("Not Now")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        
                        Button {
                            roadmapStore.vote(featureId: feature.id, type: .interested)
                            showSponsorSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("I Want This")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.voiceitPurple)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color.voiceitPurple.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.voiceitPurple.opacity(0.1), lineWidth: 1)
            )
            .sheet(isPresented: $showSponsorSheet) {
                SponsorPromptSheet(feature: feature, store: roadmapStore)
            }
            .sheet(isPresented: $showDirectSponsorForm) {
                SponsorFormView(feature: feature)
                    .environmentObject(roadmapStore)
            }
        }
    }
}
