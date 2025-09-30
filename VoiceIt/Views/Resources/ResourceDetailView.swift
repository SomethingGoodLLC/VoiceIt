import SwiftUI
import MapKit

/// Detailed view for a support resource
struct ResourceDetailView: View {
    // MARK: - Properties
    
    let resource: Resource
    
    @Environment(\.resourceService) private var resourceService
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Contact info
                if resource.phoneNumber != nil || resource.email != nil || resource.websiteURL != nil {
                    contactSection
                }
                
                // Description
                if let description = resource.resourceDescription {
                    descriptionSection(description)
                }
                
                // Location map
                if let coordinate = resource.coordinate {
                    mapSection(coordinate)
                }
                
                // Details
                detailsSection
                
                // Languages
                if !resource.languages.isEmpty {
                    languagesSection
                }
            }
            .padding()
        }
        .navigationTitle(resource.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: resource.icon)
                    .font(.largeTitle)
                    .foregroundStyle(Color.voiceitPurple)
                    .frame(width: 60, height: 60)
                    .background(Color.voiceitPurple.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(resource.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            if resource.isAvailable24_7 {
                Label("Available 24/7", systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.voiceitSuccess)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.voiceitSuccess.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Contact Section
    
    private var contactSection: some View {
        VStack(spacing: 12) {
            if let phoneNumber = resource.phoneNumber {
                Button {
                    resourceService.callResource(resource)
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text(phoneNumber)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .padding()
                    .background(Color.voiceitPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                }
            }
            
            if let email = resource.email {
                Link(destination: URL(string: "mailto:\(email)")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text(email)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .padding()
                    .background(Color.voiceitPurple.opacity(0.1))
                    .foregroundStyle(Color.voiceitPurple)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                }
            }
            
            if resource.websiteURL != nil {
                Button {
                    resourceService.openWebsite(resource)
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Visit Website")
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .padding()
                    .background(Color.voiceitPurple.opacity(0.1))
                    .foregroundStyle(Color.voiceitPurple)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                }
            }
        }
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Map Section
    
    private func mapSection(_ coordinate: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
            
            Map(position: $cameraPosition) {
                Marker(resource.name, coordinate: coordinate)
                    .tint(Color.voiceitPurple)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            
            if let address = resource.address {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                resourceService.getDirections(to: resource)
            } label: {
                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.voiceitPurple)
            }
        }
        .onAppear {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            
            if let hours = resource.operatingHours {
                detailRow(icon: "clock", label: "Hours", value: hours)
            }
            
            if resource.acceptsWalkIns {
                detailRow(icon: "person.fill.checkmark", label: "Walk-ins", value: "Accepted")
            }
            
            if let distance = resource.formattedDistance {
                detailRow(icon: "location", label: "Distance", value: distance)
            }
        }
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.voiceitPurple)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Languages Section
    
    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Languages")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(resource.languages, id: \.self) { language in
                        Text(language)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResourceDetailView(resource: Resource(
            name: "National Domestic Violence Hotline",
            type: .hotline,
            phoneNumber: "1-800-799-7233",
            websiteURL: "https://www.thehotline.org",
            resourceDescription: "24/7 confidential support for domestic violence victims",
            isAvailable24_7: true,
            languages: ["English", "Spanish", "200+ via interpretation"]
        ))
    }
}
