import SwiftUI

/// Modal sheet shown after a user votes "I Want This" on a preview feature
/// Offers an optional path to connect potential sponsors
struct SponsorPromptSheet: View {
    let feature: RoadmapFeature
    @ObservedObject var store: RoadmapStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSponsorForm = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Circle()
                    .fill(Color.voiceitPurple.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.voiceitPurple)
                    }
                    .padding(.top, 20)
                    .accessibilityHidden(true)
                
                // Text
                VStack(spacing: 12) {
                    Text("Help Us Make This Real")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("\"\(feature.title)\" is on our public roadmap.\n\nWe're a free app and build based on community interest and sponsor support.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                
                // Actions
                VStack(spacing: 16) {
                    Button {
                        showSponsorForm = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("I Know a Sponsor")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.voiceitPurple)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("I know a sponsor. Opens form.")
                    
                    Button {
                        // Vote was already tracked before this sheet opened
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("Just Voting")
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Just voting, dismiss this sheet.")
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showSponsorForm) {
                SponsorFormView(feature: feature)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SponsorPromptSheet(
        feature: RoadmapFeature.initialFeatures[0],
        store: RoadmapStore()
    )
}
