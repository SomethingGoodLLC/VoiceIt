import SwiftUI

/// A card component for displaying preview/roadmap features with voting functionality
struct PreviewFeatureCard: View {
    let feature: RoadmapFeature
    @ObservedObject var store: RoadmapStore
    @State private var showSponsorSheet = false
    @State private var showDirectSponsorForm = false
    @State private var showExplanation = false
    
    var hasVoted: Bool {
        store.hasVoted(on: feature.id)
    }
    
    var voteCounts: RoadmapStore.VoteCounts {
        store.getCounts(for: feature.id)
    }
    
    var body: some View {
        cardContent
            .contentShape(Rectangle())
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(feature.title), \(feature.status.rawValue) feature")
            .accessibilityHint(hasVoted ? "You have voted. Tap to view interface preview." : "Tap to view interface preview or use buttons to vote.")
            .sheet(isPresented: $showSponsorSheet) {
                SponsorPromptSheet(feature: feature, store: store)
            }
            .sheet(isPresented: $showDirectSponsorForm) {
                SponsorFormView(feature: feature)
                    .environmentObject(store)
            }
            .alert("Roadmap Preview", isPresented: $showExplanation) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text("This feature is currently in development. We prioritize construction based on community votes and sponsorship support.")
            }
    }
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // MARK: - Header Banner
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                    Text("Roadmap Preview")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundStyle(Color.voiceitPurple)
                
                Button {
                    showExplanation = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(Color.voiceitPurple.opacity(0.6))
                }
                .buttonStyle(BorderlessButtonStyle())
                .accessibilityLabel("What is a Roadmap Preview?")
                
                Spacer()
                
                if feature.isFundingTarget {
                    Button {
                        showDirectSponsorForm = true
                    } label: {
                        HStack(spacing: 3) {
                            Text("Needs Sponsor")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.voiceitPurple.opacity(0.08))
            
            // MARK: - Card Content
            VStack(alignment: .leading, spacing: 16) {
                // Icon Header
                HStack(alignment: .top) {
                    Image(systemName: feature.iconName)
                        .font(.system(size: 32))
                        .foregroundStyle(feature.category.color)
                        .frame(width: 50, height: 50)
                        .background(feature.category.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    Spacer()
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(feature.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(feature.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                Divider()
                
                // Footer
                if hasVoted {
                    votedFooter
                } else {
                    votingButtons
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var votedFooter: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Thanks for voting!")
                .font(.subheadline)
                .foregroundStyle(.green)
            
            Spacer()
            
            HStack(spacing: 8) {
                Label("\(voteCounts.interested)", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Color.voiceitPurple)
            }
        }
        .padding(.top, 4)
        .accessibilityLabel("You voted. \(voteCounts.interested) people want this feature.")
    }
    
    private var votingButtons: some View {
        HStack(spacing: 12) {
            Button {
                store.vote(featureId: feature.id, type: .skipped)
            } label: {
                Text("Not Now")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibilityLabel("Vote: Not important to me right now")
            
            Button {
                store.vote(featureId: feature.id, type: .interested)
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
                .padding(.vertical, 10)
                .background(Color.voiceitPurple)
                .cornerRadius(8)
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibilityLabel("Vote: I want this feature")
        }
    }
}

// MARK: - Previews

struct FeatureDetailSheet: View {
    let feature: RoadmapFeature
    @ObservedObject var store: RoadmapStore
    @Environment(\.dismiss) private var dismiss
    @State private var showSponsorSheet = false
    @State private var showDirectSponsorForm = false
    
    var hasVoted: Bool {
        store.hasVoted(on: feature.id)
    }
    
    var voteCounts: RoadmapStore.VoteCounts {
        store.getCounts(for: feature.id)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Icon
                    HStack {
                        Spacer()
                        Image(systemName: feature.iconName)
                            .font(.system(size: 60))
                            .foregroundStyle(feature.category.color)
                            .padding()
                            .background(feature.category.color.opacity(0.1))
                            .clipShape(Circle())
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Status badge (Original)
                        HStack {
                            Text(feature.status.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(feature.status.color.opacity(0.1))
                                .foregroundStyle(feature.status.color)
                                .clipShape(Capsule())
                            
                            if feature.isFundingTarget {
                                Button {
                                    showDirectSponsorForm = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Seeking Sponsor")
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .accessibilityLabel("Seeking Sponsor. Tap to refer a potential sponsor.")
                                .accessibilityHint("Double tap to open referral form")
                            }
                        }
                        
                        Text(feature.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(feature.subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        Text(feature.description)
                            .font(.body)
                            .lineSpacing(6)
                        
                        // Vote counts
                        HStack(spacing: 16) {
                            Label("\(voteCounts.interested) want this", systemImage: "heart.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.voiceitPurple)
                        }
                        .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    // Voting section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Vote")
                            .font(.headline)
                        
                        if hasVoted {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Thank you for voting! Your feedback helps us prioritize.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            VStack(spacing: 12) {
                                Button {
                                    store.vote(featureId: feature.id, type: .interested)
                                    showSponsorSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                        Text("I Want This Feature")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.voiceitPurple)
                                    .cornerRadius(12)
                                }
                                
                                Button {
                                    store.vote(featureId: feature.id, type: .skipped)
                                } label: {
                                    HStack {
                                        Image(systemName: "clock")
                                        Text("Not Important to Me Right Now")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showSponsorSheet) {
            SponsorPromptSheet(feature: feature, store: store)
        }
        .sheet(isPresented: $showDirectSponsorForm) {
            SponsorFormView(feature: feature)
                .environmentObject(store)
        }
    }
}

#Preview("Preview Card - Not Voted") {
    let store = RoadmapStore()
    return PreviewFeatureCard(
        feature: RoadmapFeature.initialFeatures[0],
        store: store
    )
    .padding()
}

#Preview("Feature Detail Sheet") {
    let store = RoadmapStore()
    return FeatureDetailSheet(
        feature: RoadmapFeature.initialFeatures[0],
        store: store
    )
}
