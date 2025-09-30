import Foundation
import SwiftData

/// Represents educational content in the resource library
@Model
@available(iOS 18, *)
final class CommunityArticle {
    /// Unique identifier
    var id: UUID
    
    /// Article title
    var title: String
    
    /// Article summary
    var summary: String
    
    /// Full content (markdown or plain text)
    var content: String
    
    /// Article category
    var category: ArticleCategory
    
    /// Content type
    var contentType: ContentType
    
    /// Author name
    var author: String
    
    /// Reading time in minutes
    var readingTime: Int
    
    /// Tags for filtering
    var tags: [String]
    
    /// Whether the article is featured
    var isFeatured: Bool
    
    /// Thumbnail URL (placeholder for now)
    var thumbnailURL: String?
    
    /// Video URL if applicable
    var videoURL: String?
    
    /// Download URL for PDFs/checklists
    var downloadURL: String?
    
    /// Publication date
    var publishedAt: Date
    
    /// Number of views
    var viewCount: Int
    
    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        content: String,
        category: ArticleCategory,
        contentType: ContentType,
        author: String,
        readingTime: Int,
        tags: [String] = [],
        isFeatured: Bool = false,
        thumbnailURL: String? = nil,
        videoURL: String? = nil,
        downloadURL: String? = nil,
        publishedAt: Date = Date(),
        viewCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.category = category
        self.contentType = contentType
        self.author = author
        self.readingTime = readingTime
        self.tags = tags
        self.isFeatured = isFeatured
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.downloadURL = downloadURL
        self.publishedAt = publishedAt
        self.viewCount = viewCount
    }
}

/// Article categories
enum ArticleCategory: String, Codable, CaseIterable {
    case legal = "Legal"
    case safety = "Safety"
    case healing = "Healing"
    case financial = "Financial"
    case childcare = "Childcare"
    case stories = "Survivor Stories"
    
    var icon: String {
        switch self {
        case .legal: return "hammer.fill"
        case .safety: return "shield.fill"
        case .healing: return "heart.fill"
        case .financial: return "dollarsign.circle.fill"
        case .childcare: return "figure.2.and.child.holdinghands"
        case .stories: return "book.fill"
        }
    }
}

/// Content types
enum ContentType: String, Codable, CaseIterable {
    case article = "Article"
    case video = "Video"
    case checklist = "Checklist"
    case guide = "Guide"
    case story = "Story"
    
    var icon: String {
        switch self {
        case .article: return "doc.text.fill"
        case .video: return "play.rectangle.fill"
        case .checklist: return "checklist"
        case .guide: return "book.fill"
        case .story: return "quote.bubble.fill"
        }
    }
}
