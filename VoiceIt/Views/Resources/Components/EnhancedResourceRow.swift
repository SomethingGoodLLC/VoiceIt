import SwiftUI

/// Enhanced row view for resources with tags and swipe actions
struct EnhancedResourceRow: View {
    let resource: Resource
    @Environment(\.resourceService) private var resourceService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: resource.icon)
                .font(.title2)
                .foregroundStyle(Color.voiceitPurple)
                .frame(width: 44, height: 44)
                .background(Color.voiceitPurple.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(resource.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let description = resource.resourceDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Tags
                HStack(spacing: 8) {
                    if resource.isAvailable24_7 {
                        TagLabel(text: "24/7", color: .voiceitSuccess)
                    }
                    
                    if resource.acceptsWalkIns {
                        TagLabel(text: "Walk-ins", color: .blue)
                    }
                    
                    if let distance = resource.formattedDistance {
                        TagLabel(text: distance, color: .gray, icon: "location.fill")
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if resource.phoneNumber != nil {
                Button {
                    resourceService.callResource(resource)
                } label: {
                    Label("Call", systemImage: "phone.fill")
                }
                .tint(.voiceitPurple)
            }
            
            if resource.coordinate != nil {
                Button {
                    resourceService.getDirections(to: resource)
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                }
                .tint(.blue)
            }
        }
    }
}
