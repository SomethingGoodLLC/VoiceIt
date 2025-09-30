import Foundation
import SwiftData

/// Represents a pro bono lawyer offering legal consultations
@Model
@available(iOS 18, *)
final class Lawyer {
    /// Unique identifier
    var id: UUID
    
    /// Full name
    var name: String
    
    /// Law firm or organization
    var firm: String
    
    /// Bar association memberships
    var barAdmissions: [String]
    
    /// Specializations
    var specializations: [LegalSpecialization]
    
    /// Professional bio
    var bio: String
    
    /// Years of experience
    var yearsOfExperience: Int
    
    /// Average rating (0-5)
    var rating: Double
    
    /// Number of reviews
    var reviewCount: Int
    
    /// States where they can practice
    var jurisdictions: [String]
    
    /// Profile photo URL (placeholder for now)
    var photoURL: String?
    
    /// Whether accepting new consultations
    var isAcceptingConsultations: Bool
    
    /// Available time slots for booking
    var availableSlots: [ConsultationTimeSlot]
    
    init(
        id: UUID = UUID(),
        name: String,
        firm: String,
        barAdmissions: [String],
        specializations: [LegalSpecialization],
        bio: String,
        yearsOfExperience: Int,
        rating: Double = 0.0,
        reviewCount: Int = 0,
        jurisdictions: [String],
        photoURL: String? = nil,
        isAcceptingConsultations: Bool = true,
        availableSlots: [ConsultationTimeSlot] = []
    ) {
        self.id = id
        self.name = name
        self.firm = firm
        self.barAdmissions = barAdmissions
        self.specializations = specializations
        self.bio = bio
        self.yearsOfExperience = yearsOfExperience
        self.rating = rating
        self.reviewCount = reviewCount
        self.jurisdictions = jurisdictions
        self.photoURL = photoURL
        self.isAcceptingConsultations = isAcceptingConsultations
        self.availableSlots = availableSlots
    }
}

/// Legal specializations
enum LegalSpecialization: String, Codable, CaseIterable {
    case domesticViolence = "Domestic Violence"
    case restrainingOrders = "Restraining Orders"
    case familyLaw = "Family Law"
    case childCustody = "Child Custody"
    case divorce = "Divorce"
    case immigration = "Immigration"
    case housing = "Housing Rights"
    
    var icon: String {
        switch self {
        case .domesticViolence: return "exclamationmark.shield.fill"
        case .restrainingOrders: return "hand.raised.fill"
        case .familyLaw: return "person.3.fill"
        case .childCustody: return "figure.2.and.child.holdinghands"
        case .divorce: return "doc.text.fill"
        case .immigration: return "globe.americas.fill"
        case .housing: return "house.fill"
        }
    }
}

/// Represents a time slot for legal consultation
struct ConsultationTimeSlot: Codable, Identifiable {
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

/// Represents a booked legal consultation
@Model
@available(iOS 18, *)
final class LegalConsultation {
    var id: UUID
    var lawyerId: UUID
    var lawyerName: String
    var date: Date
    var duration: Int
    var status: ConsultationStatus
    var meetingLink: String?
    var notes: String
    var documentsShared: [String]  // File URLs or IDs
    var reminderSet: Bool
    
    init(
        id: UUID = UUID(),
        lawyerId: UUID,
        lawyerName: String,
        date: Date,
        duration: Int = 30,
        status: ConsultationStatus = .scheduled,
        meetingLink: String? = nil,
        notes: String = "",
        documentsShared: [String] = [],
        reminderSet: Bool = false
    ) {
        self.id = id
        self.lawyerId = lawyerId
        self.lawyerName = lawyerName
        self.date = date
        self.duration = duration
        self.status = status
        self.meetingLink = meetingLink
        self.notes = notes
        self.documentsShared = documentsShared
        self.reminderSet = reminderSet
    }
}

/// Consultation status
enum ConsultationStatus: String, Codable {
    case scheduled = "Scheduled"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case followUpNeeded = "Follow-up Needed"
    
    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .completed: return "green"
        case .cancelled: return "gray"
        case .followUpNeeded: return "orange"
        }
    }
}
