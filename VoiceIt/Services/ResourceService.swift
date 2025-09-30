import Foundation
import CoreLocation
import UIKit

/// Service for finding and managing support resources (shelters, hotlines, legal aid)
final class ResourceService: Sendable {
    // MARK: - Properties
    
    /// Default resources (national hotlines and resources)
    private let defaultResources: [Resource] = [
        Resource(
            name: "National Domestic Violence Hotline",
            type: .hotline,
            phoneNumber: "1-800-799-7233",
            websiteURL: "https://www.thehotline.org",
            resourceDescription: "24/7 confidential support for domestic violence victims",
            isAvailable24_7: true,
            languages: ["English", "Spanish", "200+ other languages via interpretation"]
        ),
        Resource(
            name: "Crisis Text Line",
            type: .hotline,
            phoneNumber: "741741",
            resourceDescription: "Text HOME to 741741 for 24/7 crisis support",
            isAvailable24_7: true
        ),
        Resource(
            name: "National Sexual Assault Hotline",
            type: .hotline,
            phoneNumber: "1-800-656-4673",
            websiteURL: "https://www.rainn.org",
            resourceDescription: "24/7 confidential support for sexual assault survivors",
            isAvailable24_7: true
        ),
        Resource(
            name: "National Suicide Prevention Lifeline",
            type: .hotline,
            phoneNumber: "988",
            websiteURL: "https://988lifeline.org",
            resourceDescription: "24/7 suicide prevention and crisis support",
            isAvailable24_7: true
        ),
        Resource(
            name: "Legal Aid",
            type: .legalAid,
            phoneNumber: "1-844-292-5274",
            websiteURL: "https://www.lsc.gov",
            resourceDescription: "Free legal assistance for low-income individuals"
        )
    ]
    
    // MARK: - Find Resources
    
    /// Get all resources, optionally filtered by type
    func getResources(
        ofType type: ResourceType? = nil,
        userLocation: CLLocation? = nil
    ) async -> [Resource] {
        var resources = defaultResources
        
        // Filter by type if specified
        if let type = type {
            resources = resources.filter { $0.type == type }
        }
        
        // Calculate distances if user location provided
        if let userLocation = userLocation {
            for resource in resources {
                if let coordinate = resource.coordinate {
                    let resourceLocation = CLLocation(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    resource.distance = userLocation.distance(from: resourceLocation)
                }
            }
            
            // Sort by distance
            resources.sort { (lhs, rhs) in
                guard let lhsDistance = lhs.distance,
                      let rhsDistance = rhs.distance else {
                    return lhs.distance != nil
                }
                return lhsDistance < rhsDistance
            }
        }
        
        return resources
    }
    
    /// Find nearby physical resources (shelters, police stations, etc.)
    func findNearbyResources(
        location: CLLocation,
        radius: Double = 50000, // 50km default
        types: [ResourceType] = [.shelter, .police, .medical]
    ) async throws -> [Resource] {
        // In production, this would query a real API or database
        // For now, return filtered default resources
        
        var resources = defaultResources.filter { types.contains($0.type) }
        
        // Calculate distances
        for resource in resources {
            if let coordinate = resource.coordinate {
                let resourceLocation = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                let distance = location.distance(from: resourceLocation)
                
                if distance <= radius {
                    resource.distance = distance
                }
            }
        }
        
        // Filter out resources beyond radius and sort by distance
        resources = resources
            .filter { $0.distance != nil && $0.distance! <= radius }
            .sorted { $0.distance! < $1.distance! }
        
        return resources
    }
    
    // MARK: - Search
    
    /// Search resources by name or description
    func searchResources(query: String, in resources: [Resource]) -> [Resource] {
        let lowercasedQuery = query.lowercased()
        
        return resources.filter { resource in
            resource.name.lowercased().contains(lowercasedQuery) ||
            resource.resourceDescription?.lowercased().contains(lowercasedQuery) == true ||
            resource.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    // MARK: - Filter
    
    /// Filter resources by availability
    func filterByAvailability(resources: [Resource], available24_7: Bool? = nil) -> [Resource] {
        guard let available24_7 = available24_7 else { return resources }
        return resources.filter { $0.isAvailable24_7 == available24_7 }
    }
    
    /// Filter resources by language support
    func filterByLanguage(resources: [Resource], language: String) -> [Resource] {
        resources.filter { resource in
            resource.languages.contains { $0.lowercased() == language.lowercased() }
        }
    }
    
    // MARK: - Contact Resource
    
    /// Call resource phone number
    func callResource(_ resource: Resource) {
        guard let phoneNumber = resource.phoneNumber else { return }
        let cleanNumber = phoneNumber.filter { $0.isNumber }
        
        guard let url = URL(string: "tel://\(cleanNumber)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Open resource website
    func openWebsite(_ resource: Resource) {
        guard let urlString = resource.websiteURL,
              let url = URL(string: urlString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Get directions to resource
    func getDirections(to resource: Resource) {
        guard let coordinate = resource.coordinate else { return }
        
        let appleMapsURL = "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)"
        
        guard let url = URL(string: appleMapsURL) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
