import SwiftUI

/// Resource library with articles, videos, and downloadable guides
@available(iOS 18, *)
struct ResourceLibraryView: View {
    @Environment(\.communityService) private var communityService
    @State private var selectedCategory: ArticleCategory?
    @State private var selectedContentType: ContentType?
    @State private var selectedArticle: CommunityArticle?
    @State private var searchText = ""
    
    var filteredArticles: [CommunityArticle] {
        communityService.articles.filter { article in
            let categoryMatch = selectedCategory == nil || article.category == selectedCategory
            let contentTypeMatch = selectedContentType == nil || article.contentType == selectedContentType
            let searchMatch = searchText.isEmpty || 
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.summary.localizedCaseInsensitiveContains(searchText) ||
                article.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            
            return categoryMatch && contentTypeMatch && searchMatch
        }
    }
    
    var featuredArticles: [CommunityArticle] {
        communityService.articles.filter { $0.isFeatured }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Search Bar
                searchBar
                
                // Featured Section
                if !featuredArticles.isEmpty && searchText.isEmpty {
                    featuredSection
                }
                
                // Filters
                filtersSection
                
                // Articles Grid
                articlesGrid
            }
            .padding()
        }
        .navigationTitle("Resource Library")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedArticle) { article in
            NavigationStack {
                ArticleDetailView(article: article)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
            
            TextField("Search articles, guides, videos...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Resources")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(featuredArticles, id: \.id) { article in
                        FeaturedArticleCard(article: article)
                            .onTapGesture {
                                selectedArticle = article
                            }
                    }
                }
            }
        }
    }
    
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SimpleFilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        
                        ForEach(ArticleCategory.allCases, id: \.self) { category in
                            SimpleFilterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
            
            // Content Type Filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Type")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SimpleFilterChip(title: "All Types", isSelected: selectedContentType == nil) {
                            selectedContentType = nil
                        }
                        
                        ForEach(ContentType.allCases, id: \.self) { type in
                            SimpleFilterChip(title: type.rawValue, isSelected: selectedContentType == type) {
                                selectedContentType = type
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var articlesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Resources (\(filteredArticles.count))")
                .font(.headline)
            
            if filteredArticles.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                    ForEach(filteredArticles, id: \.id) { article in
                        ArticleCard(article: article)
                            .onTapGesture {
                                selectedArticle = article
                            }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No resources found")
                .font(.headline)
            
            Text("Try adjusting your filters or search terms.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

/// Featured article card (horizontal scrolling)
struct FeaturedArticleCard: View {
    let article: CommunityArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon/Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.voiceitPurple.opacity(0.1))
                    .frame(width: 280, height: 140)
                
                Image(systemName: article.contentType.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Color.voiceitPurple)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Type badge
                HStack {
                    Label(article.contentType.rawValue, systemImage: article.contentType.icon)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.voiceitPurple)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if article.downloadURL != nil {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(width: 280, alignment: .leading)
                
                Text(article.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(width: 280, alignment: .leading)
                
                Label("\(article.readingTime) min read", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 280)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

/// Article card (grid item)
struct ArticleCard: View {
    let article: CommunityArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.voiceitPurple.opacity(0.1))
                    .aspectRatio(1.5, contentMode: .fit)
                
                Image(systemName: article.contentType.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.voiceitPurple)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Type badge
                HStack {
                    Image(systemName: article.category.icon)
                        .font(.caption2)
                    Text(article.category.rawValue)
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.voiceitPurple.opacity(0.1))
                .foregroundStyle(Color.voiceitPurple)
                .clipShape(Capsule())
                
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Label("\(article.readingTime) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

#Preview {
    NavigationStack {
        ResourceLibraryView()
            .environment(\.communityService, CommunityService())
    }
}
