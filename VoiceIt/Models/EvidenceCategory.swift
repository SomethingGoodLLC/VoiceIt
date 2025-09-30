import Foundation
import SwiftUI

/// Categories for evidence classification
enum EvidenceCategory: String, Codable, CaseIterable, Identifiable {
    case physical = "Physical"
    case verbal = "Verbal"
    case financial = "Financial"
    case emotional = "Emotional"
    case digital = "Digital"
    case witness = "Witness"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .physical:
            return "bandage.fill"
        case .verbal:
            return "text.bubble.fill"
        case .financial:
            return "dollarsign.circle.fill"
        case .emotional:
            return "heart.fill"
        case .digital:
            return "iphone"
        case .witness:
            return "person.2.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .physical:
            return .red
        case .verbal:
            return .orange
        case .financial:
            return .green
        case .emotional:
            return .purple
        case .digital:
            return .blue
        case .witness:
            return .cyan
        case .other:
            return .gray
        }
    }
    
    var description: String {
        switch self {
        case .physical:
            return "Physical harm or injury"
        case .verbal:
            return "Threatening or abusive language"
        case .financial:
            return "Financial control or theft"
        case .emotional:
            return "Psychological or emotional abuse"
        case .digital:
            return "Messages, emails, or online harassment"
        case .witness:
            return "Witness statements or observations"
        case .other:
            return "Other types of evidence"
        }
    }
}
