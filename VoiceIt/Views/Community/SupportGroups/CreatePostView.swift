import SwiftUI

/// View for creating a new support group post
@available(iOS 18, *)
struct CreatePostView: View {
    let groupName: String
    let pseudonym: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var postContent = ""
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Privacy reminder
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Posting as: \(pseudonym)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Your identity remains anonymous")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Post content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Share your thoughts")
                        .font(.headline)
                    
                    TextEditor(text: $postContent)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.voiceitPurple.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Character count
                HStack {
                    Spacer()
                    Text("\(postContent.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        showSuccessAlert = true
                    }
                    .disabled(postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Post Shared", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your anonymous post has been shared with the \(groupName) group.")
            }
        }
    }
}

#Preview {
    CreatePostView(
        groupName: "First Steps: Breaking Free",
        pseudonym: "BravePhoenix421"
    )
}
