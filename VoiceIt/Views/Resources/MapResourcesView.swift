import SwiftUI
import MapKit

/// Map view showing nearby shelters and support services with color-coded markers
struct MapResourcesView: View {
    // MARK: - Properties
    
    @Environment(\.resourceService) private var resourceService
    @Environment(\.locationService) private var locationService
    
    let resources: [Resource]
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedResource: Resource?
    @State private var showingDetail = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(position: $cameraPosition, selection: $selectedResource) {
                // User location
                UserAnnotation()
                
                // Resource markers
                ForEach(physicalResources) { resource in
                    if let coordinate = resource.coordinate {
                        Marker(resource.name, systemImage: resource.icon, coordinate: coordinate)
                            .tint(markerColor(for: resource))
                            .tag(resource)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            
            // Selected resource card
            if let selected = selectedResource {
                ResourceMapCard(resource: selected, onTap: {
                    showingDetail = true
                })
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: selectedResource) { _, newValue in
            if let resource = newValue, let coordinate = resource.coordinate {
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
        }
        .onAppear {
            setupInitialRegion()
        }
        .sheet(isPresented: $showingDetail) {
            if let selected = selectedResource {
                NavigationStack {
                    ResourceDetailView(resource: selected)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Only resources with physical locations
    private var physicalResources: [Resource] {
        resources.filter { $0.coordinate != nil }
    }
    
    // MARK: - Helper Methods
    
    /// Marker color based on resource type
    private func markerColor(for resource: Resource) -> Color {
        switch resource.type {
        case .shelter:
            return .voiceitError // Red for immediate shelter
        case .counseling, .advocacy, .medical, .legalAid:
            return .blue // Blue for support services
        case .housing:
            return .voiceitPurple
        case .police:
            return .indigo
        case .financial:
            return .voiceitSuccess
        default:
            return .gray
        }
    }
    
    /// Setup initial map region
    private func setupInitialRegion() {
        if let userLocation = locationService.currentLocation {
            // Center on user with 50-mile radius (~80km)
            cameraPosition = .region(MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 80000,
                longitudinalMeters: 80000
            ))
        } else if let firstResource = physicalResources.first,
                  let coordinate = firstResource.coordinate {
            // Center on first resource if no user location
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            ))
        }
    }
}

#Preview {
    MapResourcesView(resources: [
        Resource(
            name: "Safe Harbor Emergency Shelter",
            type: .shelter,
            address: "1234 Market St, San Francisco, CA 94102",
            phoneNumber: "1-415-555-1234",
            resourceDescription: "Immediate emergency shelter",
            latitude: 37.7749,
            longitude: -122.4194,
            isAvailable24_7: true
        )
    ])
}
