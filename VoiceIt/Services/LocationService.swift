import Foundation
import CoreLocation
import Observation

/// Service for managing GPS location tracking with privacy controls
@Observable
final class LocationService: NSObject, @unchecked Sendable {
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    /// Current location
    var currentLocation: CLLocation?
    
    /// Current authorization status
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Whether location tracking is active
    var isTracking = false
    
    /// Location error if any
    var locationError: LocationError?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permission Management
    
    /// Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Request always permission (for background tracking)
    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Location Tracking
    
    /// Start tracking location
    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            locationError = .permissionDenied
            return
        }
        
        locationManager.startUpdatingLocation()
        isTracking = true
    }
    
    /// Stop tracking location
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
    }
    
    /// Get single location update
    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            locationError = .permissionDenied
            return
        }
        
        locationManager.requestLocation()
    }
    
    // MARK: - Geocoding
    
    /// Reverse geocode location to address
    func reverseGeocode(location: CLLocation) async throws -> CLPlacemark {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let placemark = placemarks?.first {
                    continuation.resume(returning: placemark)
                } else {
                    continuation.resume(throwing: LocationError.geocodingFailed)
                }
            }
        }
    }
    
    /// Create LocationSnapshot from current location
    func createSnapshot() async -> LocationSnapshot? {
        guard let location = currentLocation else { return nil }
        
        let snapshot = LocationSnapshot(from: location)
        
        // Try to get address
        if let placemark = try? await reverseGeocode(location: location) {
            snapshot.address = [
                placemark.subThoroughfare,
                placemark.thoroughfare
            ].compactMap { $0 }.joined(separator: " ")
            
            snapshot.city = placemark.locality
            snapshot.state = placemark.administrativeArea
            snapshot.country = placemark.country
            snapshot.postalCode = placemark.postalCode
        }
        
        return snapshot
    }
    
    // MARK: - Distance Calculation
    
    /// Calculate distance between two coordinates
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.currentLocation = location
            self.locationError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = .permissionDenied
                case .network:
                    self.locationError = .networkError
                default:
                    self.locationError = .unknown(error.localizedDescription)
                }
            } else {
                self.locationError = .unknown(error.localizedDescription)
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            
            // Stop tracking if permission revoked
            if status == .denied || status == .restricted {
                stopTracking()
            }
        }
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case permissionDenied
    case networkError
    case geocodingFailed
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .networkError:
            return "Network error while accessing location"
        case .geocodingFailed:
            return "Failed to reverse geocode location"
        case .unknown(let message):
            return message
        }
    }
}
