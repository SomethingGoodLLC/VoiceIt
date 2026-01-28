import SwiftUI

/// A banner indicating that features shown are part of the public roadmap
struct PreviewBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color.voiceitPurple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Preview Features")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("These are part of our public roadmap. We build based on community interest and sponsor support.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.voiceitPurple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.voiceitPurple.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview Features. These are part of our public roadmap.")
    }
}

#Preview {
    PreviewBanner()
        .padding()
}
