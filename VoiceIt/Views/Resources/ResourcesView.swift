import SwiftUI
import SwiftData

/// Resources view for finding support services
struct ResourcesView: View {
    // MARK: - Properties
    
    @Environment(\.resourceService) private var resourceService
    @Environment(\.locationService) private var locationService
    
    @State private var resources: [Resource] = []
    @State private var selectedType: ResourceType?
    @State private var searchText = ""
    @State private var isLoading = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Quick access hotlines
                Section("Emergency Hotlines") {
                    ForEach(emergencyHotlines) { resource in
                        ResourceRowView(resource: resource)
                    }
                }
                
                // Filter by type
                Section("Browse by Type") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            filterButton(nil, label: "All")
                            
                            ForEach([
                                ResourceType.shelter,
                                .hotline,
                                .legalAid,
                                .counseling,
                                .medical
                            ], id: \.self) { type in
                                filterButton(type, label: type.rawValue)
                            }
                        }
                    }
                }
                
                // Filtered resources
                if !filteredResources.isEmpty {
                    Section(selectedType?.rawValue ?? "All Resources") {
                        ForEach(filteredResources) { resource in
                            NavigationLink {
                                ResourceDetailView(resource: resource)
                            } label: {
                                ResourceRowView(resource: resource)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Resources")
            .searchable(text: $searchText, prompt: "Search resources")
            .task {
                await loadResources()
            }
            .refreshable {
                await loadResources()
            }
        }
    }
    
    // MARK: - Filter Button
    
    private func filterButton(_ type: ResourceType?, label: String) -> some View {
        Button {
            withAnimation {
                selectedType = type
            }
        } label: {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedType == type ? Color.voiceitPurple : Color.gray.opacity(0.2))
                .foregroundStyle(selectedType == type ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Computed Properties
    
    private var emergencyHotlines: [Resource] {
        resources.filter { $0.type == .hotline && $0.isAvailable24_7 }
    }
    
    private var filteredResources: [Resource] {
        var results = resources
        
        // Filter by type
        if let type = selectedType {
            results = results.filter { $0.type == type }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            results = resourceService.searchResources(query: searchText, in: results)
        }
        
        return results
    }
    
    // MARK: - Load Resources
    
    private func loadResources() async {
        isLoading = true
        
        let userLocation = locationService.currentLocation
        let loadedResources = await resourceService.getResources(userLocation: userLocation)
        
        await MainActor.run {
            self.resources = loadedResources
            self.isLoading = false
        }
    }
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
                if let phoneNumber = resource.phoneNumber {
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
