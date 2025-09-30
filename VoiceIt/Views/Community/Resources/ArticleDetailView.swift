import SwiftUI

/// Detail view for an article with full content
@available(iOS 18, *)
struct ArticleDetailView: View {
    let article: CommunityArticle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.communityService) private var communityService
    
    @State private var showDownloadConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Metadata
                metadataSection
                
                // Tags
                if !article.tags.isEmpty {
                    tagsSection
                }
                
                // Content
                contentSection
                
                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle(article.contentType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if article.downloadURL != nil {
                        Button {
                            downloadResource()
                        } label: {
                            Label("Download", systemImage: "arrow.down.circle")
                        }
                    }
                    
                    ShareLink(item: article.title) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            communityService.markArticleAsRead(article)
        }
        .alert("Download Complete", isPresented: $showDownloadConfirmation) {
            Button("OK") { }
        } message: {
            Text("The resource has been saved to your device.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.voiceitPurple.opacity(0.1))
                    .frame(height: 200)
                
                Image(systemName: article.contentType.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(Color.voiceitPurple)
            }
            
            // Title
            Text(article.title)
                .font(.title)
                .fontWeight(.bold)
            
            // Summary
            Text(article.summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(article.author, systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(article.publishedAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                Label("\(article.readingTime) min read", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label(article.category.rawValue, systemImage: article.category.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if article.downloadURL != nil {
                    Label("Downloadable", systemImage: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topics")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(article.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.voiceitPurple.opacity(0.1))
                            .foregroundStyle(Color.voiceitPurple)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content")
                .font(.headline)
            
            // In a real implementation, this would be markdown or rich text
            Text(article.content)
                .font(.body)
                .lineSpacing(6)
            
            // Placeholder for video if applicable
            if article.videoURL != nil {
                videoPlaceholder
            }
        }
    }
    
    private var videoPlaceholder: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .frame(height: 200)
                
                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                    
                    Text("Watch Video")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            
            Text("Video content would be embedded here in production")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if article.downloadURL != nil {
                Button {
                    downloadResource()
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download PDF")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.voiceitPurple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            if article.contentType == .checklist {
                Button {
                    // Print checklist
                } label: {
                    HStack {
                        Image(systemName: "printer")
                        Text("Print Checklist")
                    }
                    .font(.headline)
                    .foregroundStyle(Color.voiceitPurple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.voiceitPurple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func downloadResource() {
        communityService.downloadResource(article)
        showDownloadConfirmation = true
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            article: CommunityArticle(
                title: "Understanding Restraining Orders",
                summary: "A comprehensive guide to obtaining and enforcing protective orders.",
                content: "Detailed content about restraining orders, types, process, and enforcement...\n\nThis would be a much longer article with detailed information, steps, and guidance for survivors seeking protective orders.",
                category: .legal,
                contentType: .guide,
                author: "Legal Aid Society",
                readingTime: 12,
                tags: ["Legal", "Protection", "Court"],
                isFeatured: true,
                downloadURL: "https://example.com/restraining-orders.pdf"
            )
        )
        .environment(\.communityService, CommunityService())
    }
}
