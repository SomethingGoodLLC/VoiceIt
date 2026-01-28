import Foundation
import SwiftUI

/// Represents a feature on the roadmap
struct RoadmapFeature: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let iconName: String
    let category: FeatureCategory
    var status: FeatureStatus
    var isFundingTarget: Bool
    
    enum FeatureCategory: String, Codable, CaseIterable, Sendable {
        case community = "Community"
        case resources = "Resources"
        case safety = "Safety"
        case legal = "Legal"
        case therapy = "Therapy"
        
        var icon: String {
            switch self {
            case .community: return "person.3.fill"
            case .resources: return "book.fill"
            case .safety: return "shield.fill"
            case .legal: return "hammer.fill"
            case .therapy: return "heart.text.square.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .community: return .blue
            case .resources: return .orange
            case .safety: return .red
            case .legal: return .purple
            case .therapy: return .pink
            }
        }
    }
    
    enum FeatureStatus: String, Codable, Sendable {
        case preview = "Preview"
        case inProgress = "In Progress"
        case funded = "Funded"
        case live = "Live"
        
        var color: Color {
            switch self {
            case .preview: return .gray
            case .inProgress: return .blue
            case .funded: return .green
            case .live: return .primary
            }
        }
    }
    
    // Initial hardcoded data
    static let initialFeatures: [RoadmapFeature] = [
        RoadmapFeature(
            id: "support-groups",
            title: "Anonymous Support Groups",
            subtitle: "Join moderated discussions",
            description: "Safe, moderated spaces to connect with others who understand your experience. Fully anonymous and end-to-end encrypted.",
            iconName: "bubble.left.and.bubble.right.fill",
            category: .community,
            status: .preview,
            isFundingTarget: true
        ),
        RoadmapFeature(
            id: "therapy-sessions",
            title: "Free Therapy Sessions",
            subtitle: "Video sessions with licensed therapists",
            description: "Access to pro bono therapy sessions with trauma-informed professionals. Secure video calls with no records kept on device.",
            iconName: "heart.text.square.fill",
            category: .therapy,
            status: .preview,
            isFundingTarget: true
        ),
        RoadmapFeature(
            id: "legal-consultations",
            title: "Legal Consultations",
            subtitle: "Connect with pro bono lawyers",
            description: "Direct connection to legal professionals for initial consultations regarding protective orders and rights.",
            iconName: "hammer.circle.fill",
            category: .legal,
            status: .preview,
            isFundingTarget: true
        ),
        RoadmapFeature(
            id: "resource-library",
            title: "Resource Library",
            subtitle: "Articles, videos, and guides",
            description: "Comprehensive library of educational content, safety guides, and downloadable checklists.",
            iconName: "book.circle.fill",
            category: .resources,
            status: .preview, // Changed from .inProgress to .preview to use PreviewFeatureCard
            isFundingTarget: false
        ),
        RoadmapFeature(
            id: "shelter-map",
            title: "Shelter Map",
            subtitle: "Find safe locations nearby",
            description: "Real-time map of verified shelters and safe spaces with occupancy status and intake requirements.",
            iconName: "map.fill",
            category: .safety,
            status: .preview,
            isFundingTarget: true
        )
    ]
}
