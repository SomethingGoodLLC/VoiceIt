import SwiftUI

/// Detail view for a support group with discussion posts
@available(iOS 18, *)
struct SupportGroupDetailView: View {
    let group: SupportGroup
    @Environment(\.dismiss) private var dismiss
    @Environment(\.communityService) private var communityService
    
    @State private var hasJoined = false
    @State private var showReportSheet = false
    @State private var showNewPostSheet = false
    
    // Mock posts for demonstration
    @State private var posts: [MockPost] = [
        MockPost(
            author: "BravePhoenix421",
            content: "Today marks 6 months since I left. It's been hard but I'm finally starting to feel like myself again. Thank you all for the support.",
            timestamp: Date().addingTimeInterval(-3600),
            supportCount: 24,
            replyCount: 8
        ),
        MockPost(
            author: "StrongWarrior789",
            content: "Does anyone have advice on explaining this to young children? I'm struggling with what to say.",
            timestamp: Date().addingTimeInterval(-7200),
            supportCount: 12,
            replyCount: 15
        ),
        MockPost(
            author: "HopefulStar156",
            content: "Just finished my first therapy session. If you're on the fence, please do it. It helps so much.",
            timestamp: Date().addingTimeInterval(-14400),
            supportCount: 31,
            replyCount: 6
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Group Header
                groupHeader
                
                // Action Buttons
                actionButtons
                
                // Posts
                VStack(spacing: 16) {
                    ForEach(posts) { post in
                        PostCard(post: post, onReport: {
                            showReportSheet = true
                        })
                    }
                }
            }
            .padding()
        }
        .navigationTitle(group.topic)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewPostSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(!hasJoined)
            }
        }
        .sheet(isPresented: $showNewPostSheet) {
            CreatePostView(groupName: group.topic, pseudonym: communityService.myPseudonym)
        }
        .alert("Report Content", isPresented: $showReportSheet) {
            Button("Harassment", role: .destructive) { }
            Button("Spam", role: .destructive) { }
            Button("Misinformation", role: .destructive) { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Help keep this community safe by reporting harmful content.")
        }
    }
    
    private var groupHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: group.category.icon)
                    .font(.largeTitle)
                    .foregroundStyle(Color.voiceitPurple)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Label("\(group.memberCount) members", systemImage: "person.3.fill")
                        .font(.caption)
                    
                    Label(group.privacyLevel.rawValue, systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Text(group.groupDescription)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Moderated by \(group.moderator)", systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label(group.schedule, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if hasJoined {
                Button {
                    withAnimation {
                        hasJoined = false
                        communityService.leaveSupportGroup(group)
                    }
                } label: {
                    Label("Leave Group", systemImage: "person.badge.minus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button {
                    withAnimation {
                        hasJoined = true
                        communityService.joinSupportGroup(group)
                    }
                } label: {
                    Label("Join Group", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.voiceitPurple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

/// Post card component
struct PostCard: View {
    let post: MockPost
    let onReport: () -> Void
    
    @State private var hasSupported = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author and timestamp
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(post.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button(role: .destructive) {
                        onReport()
                    } label: {
                        Label("Report", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Content
            Text(post.content)
                .font(.body)
            
            Divider()
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    hasSupported.toggle()
                } label: {
                    Label("\(post.supportCount + (hasSupported ? 1 : 0))", systemImage: hasSupported ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundStyle(hasSupported ? .red : .secondary)
                }
                
                Label("\(post.replyCount)", systemImage: "bubble.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

/// Mock post model for demonstration
struct MockPost: Identifiable {
    let id = UUID()
    let author: String
    let content: String
    let timestamp: Date
    let supportCount: Int
    let replyCount: Int
}

#Preview {
    NavigationStack {
        SupportGroupDetailView(
            group: SupportGroup(
                topic: "First Steps: Breaking Free",
                groupDescription: "A safe space for those beginning their journey.",
                moderator: "Dr. Sarah Chen, LCSW",
                memberCount: 247,
                category: .firstSteps,
                schedule: "Weekly on Mondays at 7 PM EST"
            )
        )
        .environment(\.communityService, CommunityService())
    }
}
