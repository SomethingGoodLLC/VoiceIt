import SwiftUI

/// Filter chip button for resource list filters
struct FilterChip: View {
    let title: String
    let icon: String
    @Binding var isSelected: Bool
    var onTap: (() -> Void)?
    
    var body: some View {
        Button {
            if let onTap = onTap {
                onTap()
            } else {
                isSelected.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.voiceitPurple : Color.gray.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}
