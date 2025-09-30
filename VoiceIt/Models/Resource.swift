import Foundation
import SwiftData
import CoreLocation

/// Support resource (shelter, hotline, legal aid, etc.)
@available(iOS 18, *)
@Model
final class Resource: @unchecked Sendable {
    // MARK: - Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Resource name
    var name: String
    
    /// Resource type
    var type: ResourceType
    
    /// Address
    var address: String?
    
    /// Phone number
    var phoneNumber: String?
    
    /// Website URL
    var websiteURL: String?
    
    /// Email address
    var email: String?
    
    /// Description/services offered
    var resourceDescription: String?
    
    /// Operating hours
    var operatingHours: String?
    
    /// Latitude (if physical location)
    var latitude: Double?
    
    /// Longitude (if physical location)
    var longitude: Double?
    
    /// Distance from user in meters (calculated, not persisted)
    var distance: Double?
    
    /// Whether this resource is available 24/7
    var isAvailable24_7: Bool
    
    /// Whether this resource accepts walk-ins
    var acceptsWalkIns: Bool
    
    /// Languages supported
    var languages: [String]
    
    /// Tags for filtering
    var tags: [String]
    
    /// User rating (if applicable)
    var rating: Double?
    
    /// Whether this is a user-added resource
    var isUserAdded: Bool
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        type: ResourceType,
        address: String? = nil,
        phoneNumber: String? = nil,
        websiteURL: String? = nil,
        email: String? = nil,
        resourceDescription: String? = nil,
        operatingHours: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        distance: Double? = nil,
        isAvailable24_7: Bool = false,
        acceptsWalkIns: Bool = false,
        languages: [String] = ["English"],
        tags: [String] = [],
        rating: Double? = nil,
        isUserAdded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.address = address
        self.phoneNumber = phoneNumber
        self.websiteURL = websiteURL
        self.email = email
        self.resourceDescription = resourceDescription
        self.operatingHours = operatingHours
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.isAvailable24_7 = isAvailable24_7
        self.acceptsWalkIns = acceptsWalkIns
        self.languages = languages
        self.tags = tags
        self.rating = rating
        self.isUserAdded = isUserAdded
    }
    
    // MARK: - Computed Properties
    
    /// Coordinate if location is available
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    /// Formatted distance string
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    /// Icon for resource type
    var icon: String {
        type.icon
    }
    
    /// Color for resource type
    var color: String {
        type.color
    }
}

// MARK: - Resource Type

enum ResourceType: String, Codable {
    case shelter = "Shelter"
    case hotline = "Hotline"
    case legalAid = "Legal Aid"
    case counseling = "Counseling"
    case medical = "Medical"
    case police = "Police Station"
    case advocacy = "Advocacy"
    case housing = "Housing"
    case financial = "Financial Aid"
    case education = "Education"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .shelter:
            return "house.circle.fill"
        case .hotline:
            return "phone.circle.fill"
        case .legalAid:
            return "briefcase.circle.fill"
        case .counseling:
            return "heart.circle.fill"
        case .medical:
            return "cross.circle.fill"
        case .police:
            return "shield.circle.fill"
        case .advocacy:
            return "megaphone.circle.fill"
        case .housing:
            return "building.2.circle.fill"
        case .financial:
            return "dollarsign.circle.fill"
        case .education:
            return "book.circle.fill"
        case .other:
            return "info.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .shelter:
            return "blue"
        case .hotline:
            return "green"
        case .legalAid:
            return "purple"
        case .counseling:
            return "pink"
        case .medical:
            return "red"
        case .police:
            return "indigo"
        case .advocacy:
            return "orange"
        case .housing:
            return "teal"
        case .financial:
            return "mint"
        case .education:
            return "cyan"
        case .other:
            return "gray"
        }
    }
}
