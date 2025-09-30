import Foundation
import SwiftData

/// Emergency contact for quick access during crisis
@available(iOS 18, *)
@Model
final class EmergencyContact {
    // MARK: - Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Contact name
    var name: String
    
    /// Phone number
    var phoneNumber: String
    
    /// Relationship to user
    var relationship: String
    
    /// Whether this contact should be auto-notified in emergencies
    var autoNotify: Bool
    
    /// Whether this is a primary contact
    var isPrimary: Bool
    
    /// Optional email address
    var email: String?
    
    /// Optional notes
    var notes: String?
    
    /// Order priority (lower = higher priority)
    var priority: Int
    
    /// Last contacted timestamp
    var lastContacted: Date?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String,
        relationship: String,
        autoNotify: Bool = false,
        isPrimary: Bool = false,
        email: String? = nil,
        notes: String? = nil,
        priority: Int = 0,
        lastContacted: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
        self.autoNotify = autoNotify
        self.isPrimary = isPrimary
        self.email = email
        self.notes = notes
        self.priority = priority
        self.lastContacted = lastContacted
    }
    
    // MARK: - Computed Properties
    
    /// Formatted phone number for display
    var formattedPhoneNumber: String {
        // Basic formatting - can be enhanced
        phoneNumber
    }
    
    /// Display name with relationship
    var displayName: String {
        "\(name) (\(relationship))"
    }
    
    /// Icon based on relationship
    var icon: String {
        switch relationship.lowercased() {
        case "friend":
            return "person.circle.fill"
        case "family", "parent", "sibling":
            return "person.2.circle.fill"
        case "lawyer", "attorney":
            return "briefcase.circle.fill"
        case "therapist", "counselor":
            return "heart.circle.fill"
        case "doctor", "physician":
            return "stethoscope.circle.fill"
        default:
            return "phone.circle.fill"
        }
    }
}
