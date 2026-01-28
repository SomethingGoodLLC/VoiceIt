import SwiftUI
import SwiftData

/// Resources view for finding support services
struct ResourcesView: View {
    // MARK: - Properties
    
    @Environment(\.resourceService) private var resourceService
    @Environment(\.locationService) private var locationService
    
    @State private var resources: [Resource] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var selectedTab: ResourceTab = .contacts // Default to Contacts as verified source
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("View", selection: $selectedTab) {
                    Label("Map", systemImage: "map.fill")
                        .tag(ResourceTab.map)
                    Label("List", systemImage: "list.bullet")
                        .tag(ResourceTab.list)
                    Label("Contacts", systemImage: "phone.fill")
                        .tag(ResourceTab.contacts)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Disclaimer banner
                disclaimerBanner
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Tab content
                Group {
                    switch selectedTab {
                    case .map:
                        ZStack(alignment: .top) {
                            MapResourcesView(resources: resources)
                                .overlay(Color.black.opacity(0.05)) // Dim map slightly to show it's less prioritized? Or just keep as is but add banner.
                                // Actually, user said "make that show as a preview/ I want this".
                                // So we should probably overlay the preview banner on the map.
                            
                            RoadmapPreviewBanner(featureId: "shelter-map") // We need to add this feature ID
                                .padding()
                        }
                    case .list:
                        EnhancedListResourcesView(
                            resources: resources,
                            searchText: $searchText
                        )
                    case .contacts:
                        QuickContactsView()
                    }
                }
            }
            .navigationTitle("Resources")
            .searchable(text: $searchText, prompt: "Search resources")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .task {
                await loadResources()
            }
            .refreshable {
                await refreshResources()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await refreshResources()
                            }
                        } label: {
                            Label("Refresh Resources", systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            requestLocationIfNeeded()
                        } label: {
                            Label("Update Location", systemImage: "location.fill")
                        }
                        
                        Divider()
                        
                        if locationService.currentLocation != nil {
                            Text("Last updated: \(Date(), style: .relative)")
                                .font(.caption)
                        } else {
                            Text("Location: Not available")
                                .font(.caption)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Disclaimer Banner
    
    private var disclaimerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Demo Resources")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Sample data shown. Verify resources before use.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Load Resources
    
    private func loadResources() async {
        isLoading = true
        
        // Request location permission if needed
        if locationService.authorizationStatus == .notDetermined {
            locationService.requestPermission()
        }
        
        // Start tracking if authorized
        if !locationService.isTracking,
           (locationService.authorizationStatus == .authorizedWhenInUse ||
            locationService.authorizationStatus == .authorizedAlways) {
            locationService.requestLocation()
        }
        
        let userLocation = locationService.currentLocation
        let loadedResources = await resourceService.getResources(userLocation: userLocation)
        
        await MainActor.run {
            self.resources = loadedResources
            self.isLoading = false
        }
    }
    
    private func refreshResources() async {
        // Clear cache to force fresh data
        resourceService.clearCache()
        
        // Request new location
        locationService.requestLocation()
        
        // Small delay to let location update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Reload resources
        await loadResources()
    }
    
    private func requestLocationIfNeeded() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            locationService.requestLocation()
        case .denied, .restricted:
            // Show alert to user
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Resource Tab

enum ResourceTab: String, CaseIterable {
    case map = "Map"
    case list = "List"
    case contacts = "Contacts"
}

// MARK: - Resource Row View

struct ResourceRowView: View {
    let resource: Resource
    @Environment(\.resourceService) private var resourceService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: resource.icon)
                .font(.title2)
                .foregroundStyle(Color.voiceitPurple)
                .frame(width: 40, height: 40)
                .background(Color.voiceitPurple.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(resource.name)
                    .font(.headline)
                
                if let description = resource.resourceDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    if resource.isAvailable24_7 {
                        Label("24/7", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(Color.voiceitSuccess)
                    }
                    
                    if let distance = resource.formattedDistance {
                        Label(distance, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Quick actions
                if resource.phoneNumber != nil {
                    Button {
                        resourceService.callResource(resource)
                    } label: {
                        Label("Call Now", systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(Color.voiceitPurple)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ResourcesView()
}
