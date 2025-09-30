import SwiftUI
import MapKit

/// Map card showing resource details when marker is tapped
struct ResourceMapCard: View {
    let resource: Resource
    let onTap: () -> Void
    
    @Environment(\.resourceService) private var resourceService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: resource.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.voiceitPurple)
                    .clipShape(Circle())
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(resource.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let address = resource.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                if resource.phoneNumber != nil {
                    Button {
                        resourceService.callResource(resource)
                    } label: {
                        Label("Call", systemImage: "phone.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.voiceitPurple)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                
                Button {
                    resourceService.getDirections(to: resource)
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.voiceitPurple.opacity(0.1))
                        .foregroundStyle(Color.voiceitPurple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .onTapGesture {
            onTap()
        }
    }
}
