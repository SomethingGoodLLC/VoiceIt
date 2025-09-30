import Foundation
import SwiftData
import CoreLocation

/// GPS location snapshot associated with evidence
@available(iOS 18, *)
@Model
final class LocationSnapshot {
    // MARK: - Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Timestamp when location was captured
    var timestamp: Date
    
    /// Latitude coordinate
    var latitude: Double
    
    /// Longitude coordinate
    var longitude: Double
    
    /// Altitude in meters (optional)
    var altitude: Double?
    
    /// Horizontal accuracy in meters
    var horizontalAccuracy: Double
    
    /// Vertical accuracy in meters (optional)
    var verticalAccuracy: Double?
    
    /// Reverse-geocoded address
    var address: String?
    var city: String?
    var state: String?
    var country: String?
    var postalCode: String?
    
    /// Speed in meters per second (optional)
    var speed: Double?
    
    /// Course/heading in degrees (optional)
    var course: Double?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        horizontalAccuracy: Double,
        verticalAccuracy: Double? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        postalCode: String? = nil,
        speed: Double? = nil,
        course: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.address = address
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
        self.speed = speed
        self.course = course
    }
    
    // MARK: - Convenience Initializer
    
    /// Initialize from CLLocation
    convenience init(from location: CLLocation) {
        self.init(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            speed: location.speed >= 0 ? location.speed : nil,
            course: location.course >= 0 ? location.course : nil
        )
    }
    
    // MARK: - Computed Properties
    
    /// Coordinate as CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Formatted coordinates string
    var coordinatesString: String {
        String(format: "%.6f, %.6f", latitude, longitude)
    }
    
    /// Full address string
    var fullAddress: String {
        [address, city, state, postalCode, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
    
    /// Short address (street + city)
    var shortAddress: String {
        [address, city]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
    
    /// Accuracy quality indicator
    var accuracyQuality: LocationAccuracyQuality {
        switch horizontalAccuracy {
        case ..<10:
            return .excellent
        case 10..<50:
            return .good
        case 50..<100:
            return .fair
        default:
            return .poor
        }
    }
}

// MARK: - Location Accuracy Quality

enum LocationAccuracyQuality: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "orange"
        case .poor:
            return "red"
        }
    }
}
