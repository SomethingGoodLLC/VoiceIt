import Foundation
import CoreLocation
import UIKit

/// Service for finding and managing support resources (shelters, hotlines, legal aid)
@MainActor
final class ResourceService {
    // MARK: - Properties
    
    /// Cached resources
    private var cachedResources: [Resource]?
    private var lastCacheUpdate: Date?
    private let cacheExpirationInterval: TimeInterval = 604800 // 7 days
    
    /// Init can be called from nonisolated context since Resource instances don't require MainActor
    nonisolated(unsafe) init() {}
    
    /// Default resources (national hotlines and local resources)
    private let defaultResources: [Resource] = [
        // EMERGENCY HOTLINES (24/7)
        Resource(
            name: "National Domestic Violence Hotline",
            type: .hotline,
            phoneNumber: "1-800-799-7233",
            websiteURL: "https://www.thehotline.org",
            resourceDescription: "24/7 confidential support for domestic violence victims",
            isAvailable24_7: true,
            languages: ["English", "Spanish", "200+ other languages via interpretation"],
            tags: ["crisis", "counseling", "safety planning"]
        ),
        Resource(
            name: "Crisis Text Line",
            type: .hotline,
            phoneNumber: "741741",
            resourceDescription: "Text HOME to 741741 for 24/7 crisis support",
            isAvailable24_7: true,
            tags: ["crisis", "text support", "anonymous"]
        ),
        Resource(
            name: "National Sexual Assault Hotline",
            type: .hotline,
            phoneNumber: "1-800-656-4673",
            websiteURL: "https://www.rainn.org",
            resourceDescription: "24/7 confidential support for sexual assault survivors",
            isAvailable24_7: true,
            tags: ["crisis", "assault", "counseling"]
        ),
        Resource(
            name: "National Suicide Prevention Lifeline",
            type: .hotline,
            phoneNumber: "988",
            websiteURL: "https://988lifeline.org",
            resourceDescription: "24/7 suicide prevention and crisis support",
            isAvailable24_7: true,
            tags: ["crisis", "mental health", "suicide prevention"]
        ),
        
        // SHELTERS (Sample locations - San Francisco Bay Area)
        Resource(
            name: "Safe Harbor Emergency Shelter",
            type: .shelter,
            address: "1234 Market St, San Francisco, CA 94102",
            phoneNumber: "1-415-555-1234",
            websiteURL: "https://safeharborsf.org",
            resourceDescription: "Immediate emergency shelter with 24/7 access. Beds, meals, and safety planning services.",
            operatingHours: "24/7 Access",
            latitude: 37.7749,
            longitude: -122.4194,
            isAvailable24_7: true,
            acceptsWalkIns: true,
            languages: ["English", "Spanish", "Cantonese"],
            tags: ["emergency shelter", "immediate help", "meals included"]
        ),
        Resource(
            name: "Horizon House Women's Shelter",
            type: .shelter,
            address: "567 Mission St, San Francisco, CA 94105",
            phoneNumber: "1-415-555-5678",
            websiteURL: "https://horizonhouse.org",
            resourceDescription: "Women and children's shelter with long-term housing program. Childcare available.",
            operatingHours: "Mon-Fri 9AM-5PM, 24/7 Emergency Line",
            latitude: 37.7849,
            longitude: -122.4094,
            isAvailable24_7: true,
            acceptsWalkIns: false,
            languages: ["English", "Spanish"],
            tags: ["women", "children", "long-term housing", "childcare"]
        ),
        Resource(
            name: "Bridge to Safety Shelter",
            type: .shelter,
            address: "890 Oak St, Oakland, CA 94607",
            phoneNumber: "1-510-555-8900",
            websiteURL: "https://bridgetosafety.org",
            resourceDescription: "Confidential location shelter with trauma-informed care and legal advocacy.",
            operatingHours: "24/7 Intake",
            latitude: 37.8044,
            longitude: -122.2712,
            isAvailable24_7: true,
            acceptsWalkIns: true,
            languages: ["English", "Spanish", "Vietnamese"],
            tags: ["confidential", "legal advocacy", "trauma care"]
        ),
        
        // LEGAL AID
        Resource(
            name: "Legal Aid Society - DV Division",
            type: .legalAid,
            address: "123 Van Ness Ave, San Francisco, CA 94102",
            phoneNumber: "1-844-292-5274",
            websiteURL: "https://www.lsc.gov",
            email: "help@legalaid.org",
            resourceDescription: "Free legal assistance for restraining orders, custody, and divorce cases.",
            operatingHours: "Mon-Fri 9AM-5PM",
            latitude: 37.7799,
            longitude: -122.4200,
            languages: ["English", "Spanish", "Chinese"],
            tags: ["restraining orders", "custody", "divorce", "free"]
        ),
        Resource(
            name: "Bay Area Legal Aid",
            type: .legalAid,
            address: "1800 Market St #300, San Francisco, CA 94102",
            phoneNumber: "1-415-555-2020",
            websiteURL: "https://baylegal.org",
            email: "intake@baylegal.org",
            resourceDescription: "Legal representation for low-income domestic violence survivors.",
            operatingHours: "Mon-Fri 9AM-5PM, Wed until 7PM",
            latitude: 37.7699,
            longitude: -122.4250,
            languages: ["English", "Spanish"],
            tags: ["legal representation", "low-income", "court advocacy"]
        ),
        
        // COUNSELING & SUPPORT
        Resource(
            name: "Women's Trauma Recovery Center",
            type: .counseling,
            address: "456 Geary St, San Francisco, CA 94102",
            phoneNumber: "1-415-555-3456",
            websiteURL: "https://traumacenter.org",
            email: "info@traumacenter.org",
            resourceDescription: "Individual and group therapy for trauma survivors. Sliding scale fees.",
            operatingHours: "Mon-Fri 8AM-8PM, Sat 10AM-4PM",
            latitude: 37.7869,
            longitude: -122.4100,
            languages: ["English", "Spanish", "Tagalog"],
            tags: ["therapy", "group support", "sliding scale", "trauma"]
        ),
        Resource(
            name: "Family Justice Center",
            type: .advocacy,
            address: "730 Polk St, San Francisco, CA 94102",
            phoneNumber: "1-415-551-9595",
            websiteURL: "https://fjcsf.org",
            resourceDescription: "One-stop center: legal, medical, counseling, and advocacy services.",
            operatingHours: "Mon-Fri 9AM-5PM",
            latitude: 37.7819,
            longitude: -122.4180,
            isAvailable24_7: false,
            acceptsWalkIns: true,
            languages: ["English", "Spanish", "Chinese", "Tagalog"],
            tags: ["comprehensive services", "walk-ins", "advocacy"]
        ),
        
        // MEDICAL & HEALTH
        Resource(
            name: "San Francisco General Hospital - DV Services",
            type: .medical,
            address: "1001 Potrero Ave, San Francisco, CA 94110",
            phoneNumber: "1-415-206-8000",
            websiteURL: "https://zsfg.org",
            resourceDescription: "24/7 emergency care with specialized domestic violence response team.",
            operatingHours: "24/7 Emergency Department",
            latitude: 37.7569,
            longitude: -122.4046,
            isAvailable24_7: true,
            acceptsWalkIns: true,
            languages: ["English", "Spanish", "Chinese", "Russian"],
            tags: ["emergency care", "forensic exams", "medical records"]
        ),
        
        // HOUSING ASSISTANCE
        Resource(
            name: "Transitional Housing Program",
            type: .housing,
            address: "234 Valencia St, San Francisco, CA 94103",
            phoneNumber: "1-415-555-7890",
            websiteURL: "https://transitionalhousing.org",
            email: "housing@thp.org",
            resourceDescription: "Up to 24-month housing assistance with case management and job training.",
            operatingHours: "Mon-Fri 9AM-5PM",
            latitude: 37.7669,
            longitude: -122.4213,
            languages: ["English", "Spanish"],
            tags: ["long-term", "job training", "case management"]
        ),
        
        // FINANCIAL ASSISTANCE
        Resource(
            name: "Emergency Financial Assistance Fund",
            type: .financial,
            address: "100 Larkin St, San Francisco, CA 94102",
            phoneNumber: "1-415-555-1000",
            websiteURL: "https://financialaid.org",
            email: "grants@financialaid.org",
            resourceDescription: "Emergency grants for rent, utilities, and relocation costs.",
            operatingHours: "Mon-Fri 9AM-5PM",
            latitude: 37.7795,
            longitude: -122.4172,
            languages: ["English", "Spanish"],
            tags: ["emergency funds", "rent assistance", "relocation"]
        )
    ]
    
    // MARK: - Find Resources
    
    /// Get all resources, optionally filtered by type
    func getResources(
        ofType type: ResourceType? = nil,
        userLocation: CLLocation? = nil
    ) async -> [Resource] {
        // Check cache first
        if let cached = cachedResources,
           let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheExpirationInterval {
            var resources = cached
            
            // Filter and process cached results
            if let type = type {
                resources = resources.filter { $0.type == type }
            }
            
            return processResources(resources, userLocation: userLocation)
        }
        
        // Load fresh data (in production, this would fetch from API)
        var resources = defaultResources
        
        // Cache the results
        cachedResources = resources
        lastCacheUpdate = Date()
        
        // Filter by type if specified
        if let type = type {
            resources = resources.filter { $0.type == type }
        }
        
        return processResources(resources, userLocation: userLocation)
    }
    
    /// Process resources (calculate distances, sort)
    private func processResources(_ resources: [Resource], userLocation: CLLocation?) -> [Resource] {
        var processed = resources
        
        // Calculate distances if user location provided
        if let userLocation = userLocation {
            for resource in processed {
                if let coordinate = resource.coordinate {
                    let resourceLocation = CLLocation(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                    resource.distance = userLocation.distance(from: resourceLocation)
                }
            }
            
            // Sort by distance
            processed.sort { (lhs, rhs) in
                guard let lhsDistance = lhs.distance,
                      let rhsDistance = rhs.distance else {
                    return lhs.distance != nil
                }
                return lhsDistance < rhsDistance
            }
        }
        
        return processed
    }
    
    /// Clear cache (force refresh)
    func clearCache() {
        cachedResources = nil
        lastCacheUpdate = nil
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
