import SwiftUI
import CoreLocation

/// Enhanced list view for resources with advanced filtering, sorting, and search
struct EnhancedListResourcesView: View {
    // MARK: - Properties
    
    @Environment(\.resourceService) private var resourceService
    @Environment(\.locationService) private var locationService
    
    let resources: [Resource]
    @Binding var searchText: String
    
    @State private var selectedType: ResourceType?
    @State private var showOnlyOpenNow = false
    @State private var showOnly24_7 = false
    @State private var maxDistance: Double = 80000 // 50 miles in meters
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Filter chips
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "24/7",
                            icon: "clock.fill",
                            isSelected: $showOnly24_7
                        )
                        
                        FilterChip(
                            title: "<5 miles",
                            icon: "location.fill",
                            isSelected: .constant(maxDistance == 8000)
                        ) {
                            maxDistance = maxDistance == 8000 ? 80000 : 8000
                        }
                        
                        FilterChip(
                            title: "Open Now",
                            icon: "door.left.hand.open",
                            isSelected: $showOnlyOpenNow
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Category filters
            Section("Browse by Type") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ResourceCategoryButton(
                            type: nil,
                            label: "All",
                            isSelected: selectedType == nil
                        ) {
                            selectedType = nil
                        }
                        
                        ForEach([
                            ResourceType.shelter,
                            .hotline,
                            .legalAid,
                            .counseling,
                            .medical,
                            .housing,
                            .financial
                        ], id: \.self) { type in
                            ResourceCategoryButton(
                                type: type,
                                label: type.rawValue,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                            }
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Emergency hotlines section
            if !emergencyHotlines.isEmpty && selectedType == nil {
                Section("Emergency Hotlines") {
                    ForEach(emergencyHotlines) { resource in
                        NavigationLink {
                            ResourceDetailView(resource: resource)
                        } label: {
                            EnhancedResourceRow(resource: resource)
                        }
                    }
                }
            }
            
            // Filtered resources
            if !filteredResources.isEmpty {
                Section(sectionTitle) {
                    ForEach(filteredResources) { resource in
                        NavigationLink {
                            ResourceDetailView(resource: resource)
                        } label: {
                            EnhancedResourceRow(resource: resource)
                        }
                    }
                }
            } else if !resources.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text("No resources match your filters")
                            .font(.headline)
                        
                        Text("Try adjusting your search or filters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Computed Properties
    
    private var emergencyHotlines: [Resource] {
        resources.filter { $0.type == .hotline && $0.isAvailable24_7 }
    }
    
    private var filteredResources: [Resource] {
        var results = resources.filter { $0.type != .hotline }
        
        // Filter by selected type
        if let type = selectedType {
            results = results.filter { $0.type == type }
        }
        
        // Filter by 24/7 availability
        if showOnly24_7 {
            results = results.filter { $0.isAvailable24_7 }
        }
        
        // Filter by distance
        if let userLocation = locationService.currentLocation {
            results = results.filter { resource in
                guard let coordinate = resource.coordinate else { return false }
                let distance = locationService.distance(
                    from: userLocation.coordinate,
                    to: coordinate
                )
                return distance <= maxDistance
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            results = resourceService.searchResources(query: searchText, in: results)
        }
        
        return results
    }
    
    private var sectionTitle: String {
        if let type = selectedType {
            return type.rawValue
        }
        return "All Resources"
    }
}

#Preview {
    NavigationStack {
        EnhancedListResourcesView(
            resources: [
                Resource(
                    name: "Safe Harbor Emergency Shelter",
                    type: .shelter,
                    phoneNumber: "1-415-555-1234",
                    resourceDescription: "Immediate emergency shelter with 24/7 access",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    isAvailable24_7: true,
                    acceptsWalkIns: true
                )
            ],
            searchText: .constant("")
        )
    }
}
