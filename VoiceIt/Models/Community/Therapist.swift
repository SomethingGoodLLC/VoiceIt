import Foundation
import SwiftData

/// Represents a licensed therapist offering pro bono sessions
@Model
@available(iOS 18, *)
final class Therapist {
    /// Unique identifier
    var id: UUID
    
    /// Full name
    var name: String
    
    /// Professional credentials (e.g., "LCSW", "PhD", "PsyD")
    var credentials: String
    
    /// Professional bio
    var bio: String
    
    /// Specializations
    var specializations: [String]
    
    /// Years of experience
    var yearsOfExperience: Int
    
    /// Available languages
    var languages: [String]
    
    /// Average rating (0-5)
    var rating: Double
    
    /// Number of reviews
    var reviewCount: Int
    
    /// Profile photo URL (placeholder for now)
    var photoURL: String?
    
    /// Whether accepting new clients
    var isAcceptingClients: Bool
    
    /// Available time slots for booking
    var availableSlots: [TherapyTimeSlot]
    
    init(
        id: UUID = UUID(),
        name: String,
        credentials: String,
        bio: String,
        specializations: [String],
        yearsOfExperience: Int,
        languages: [String] = ["English"],
        rating: Double = 0.0,
        reviewCount: Int = 0,
        photoURL: String? = nil,
        isAcceptingClients: Bool = true,
        availableSlots: [TherapyTimeSlot] = []
    ) {
        self.id = id
        self.name = name
        self.credentials = credentials
        self.bio = bio
        self.specializations = specializations
        self.yearsOfExperience = yearsOfExperience
        self.languages = languages
        self.rating = rating
        self.reviewCount = reviewCount
        self.photoURL = photoURL
        self.isAcceptingClients = isAcceptingClients
        self.availableSlots = availableSlots
    }
}

/// Represents a time slot for therapy booking
struct TherapyTimeSlot: Codable, Identifiable {
    var id: UUID
    var date: Date
    var duration: Int  // in minutes
    var isAvailable: Bool
    
    init(id: UUID = UUID(), date: Date, duration: Int = 30, isAvailable: Bool = true) {
        self.id = id
        self.date = date
        self.duration = duration
        self.isAvailable = isAvailable
    }
}

/// Represents a booked therapy session
@Model
@available(iOS 18, *)
final class TherapySession {
    var id: UUID
    var therapistId: UUID
    var therapistName: String
    var date: Date
    var duration: Int
    var status: SessionStatus
    var meetingLink: String?
    var notes: String
    var reminderSet: Bool
    
    init(
        id: UUID = UUID(),
        therapistId: UUID,
        therapistName: String,
        date: Date,
        duration: Int = 30,
        status: SessionStatus = .scheduled,
        meetingLink: String? = nil,
        notes: String = "",
        reminderSet: Bool = false
    ) {
        self.id = id
        self.therapistId = therapistId
        self.therapistName = therapistName
        self.date = date
        self.duration = duration
        self.status = status
        self.meetingLink = meetingLink
        self.notes = notes
        self.reminderSet = reminderSet
    }
}

/// Session status
enum SessionStatus: String, Codable {
    case scheduled = "Scheduled"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case noShow = "No Show"
    
    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .completed: return "green"
        case .cancelled: return "gray"
        case .noShow: return "red"
        }
    }
}
