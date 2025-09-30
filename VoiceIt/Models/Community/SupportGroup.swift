import Foundation
import SwiftData

/// Represents an anonymous support group discussion topic
@Model
@available(iOS 18, *)
final class SupportGroup {
    /// Unique identifier
    var id: UUID
    
    /// Group topic/name
    var topic: String
    
    /// Description of the group
    var groupDescription: String
    
    /// Moderator name or title
    var moderator: String
    
    /// Number of active members
    var memberCount: Int
    
    /// Category (e.g., "First Steps", "Legal Journey", "Healing & Recovery")
    var category: SupportGroupCategory
    
    /// Whether the group is currently accepting new members
    var isAcceptingMembers: Bool
    
    /// Meeting schedule (e.g., "Weekly on Mondays")
    var schedule: String
    
    /// Privacy level
    var privacyLevel: PrivacyLevel
    
    /// Creation date
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        topic: String,
        groupDescription: String,
        moderator: String,
        memberCount: Int,
        category: SupportGroupCategory,
        isAcceptingMembers: Bool = true,
        schedule: String,
        privacyLevel: PrivacyLevel = .anonymous,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.topic = topic
        self.groupDescription = groupDescription
        self.moderator = moderator
        self.memberCount = memberCount
        self.category = category
        self.isAcceptingMembers = isAcceptingMembers
        self.schedule = schedule
        self.privacyLevel = privacyLevel
        self.createdAt = createdAt
    }
}

/// Support group categories
enum SupportGroupCategory: String, Codable, CaseIterable {
    case firstSteps = "First Steps"
    case legalJourney = "Legal Journey"
    case healingRecovery = "Healing & Recovery"
    case parentingSupport = "Parenting Support"
    case financialIndependence = "Financial Independence"
    
    var icon: String {
        switch self {
        case .firstSteps: return "figure.walk"
        case .legalJourney: return "hammer.fill"
        case .healingRecovery: return "heart.fill"
        case .parentingSupport: return "figure.2.and.child.holdinghands"
        case .financialIndependence: return "dollarsign.circle.fill"
        }
    }
}

/// Privacy levels for community features
enum PrivacyLevel: String, Codable {
    case anonymous = "Anonymous"
    case pseudonym = "Pseudonym"
    case verified = "Verified"
}

/// Represents a post in a support group
@Model
@available(iOS 18, *)
final class SupportGroupPost {
    var id: UUID
    var supportGroupId: UUID
    var authorPseudonym: String
    var content: String
    var replyCount: Int
    var supportCount: Int  // Like "likes" but more sensitive terminology
    var createdAt: Date
    var isModerated: Bool
    var isFlagged: Bool
    
    init(
        id: UUID = UUID(),
        supportGroupId: UUID,
        authorPseudonym: String,
        content: String,
        replyCount: Int = 0,
        supportCount: Int = 0,
        createdAt: Date = Date(),
        isModerated: Bool = false,
        isFlagged: Bool = false
    ) {
        self.id = id
        self.supportGroupId = supportGroupId
        self.authorPseudonym = authorPseudonym
        self.content = content
        self.replyCount = replyCount
        self.supportCount = supportCount
        self.createdAt = createdAt
        self.isModerated = isModerated
        self.isFlagged = isFlagged
    }
}
