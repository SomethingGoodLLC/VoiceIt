import SwiftUI

/// Community support and education view
struct CommunityView: View {
    // MARK: - Properties
    
    @State private var selectedSection: CommunitySection = .education
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Section picker
                    sectionPicker
                    
                    // Content based on selected section
                    contentSection
                }
                .padding()
            }
            .navigationTitle("Community")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    Color.voiceitGradient
                )
            
            Text("You Are Not Alone")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Support, education, and resources for your journey")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Section Picker
    
    private var sectionPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(CommunitySection.allCases, id: \.self) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private var contentSection: some View {
        switch selectedSection {
        case .education:
            educationContent
        case .support:
            supportContent
        case .safety:
            safetyContent
        }
    }
    
    // MARK: - Education Content
    
    private var educationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Educational Resources")
                .font(.title2)
                .fontWeight(.bold)
            
            educationCard(
                icon: "book.fill",
                title: "Understanding Your Rights",
                description: "Learn about legal protections and your rights"
            )
            
            educationCard(
                icon: "heart.text.square.fill",
                title: "Recognizing Patterns",
                description: "Understanding signs and cycles"
            )
            
            educationCard(
                icon: "shield.lefthalf.filled",
                title: "Safety Planning",
                description: "Creating a comprehensive safety plan"
            )
            
            educationCard(
                icon: "person.2.fill",
                title: "Supporting Others",
                description: "How to help someone in need"
            )
        }
    }
    
    // MARK: - Support Content
    
    private var supportContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support Networks")
                .font(.title2)
                .fontWeight(.bold)
            
            supportCard(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Online Support Groups",
                description: "Connect with others who understand",
                badge: "Moderated"
            )
            
            supportCard(
                icon: "person.3.fill",
                title: "Local Support Groups",
                description: "Find in-person support near you"
            )
            
            supportCard(
                icon: "mic.fill",
                title: "Share Your Story",
                description: "Healing through sharing (anonymous)",
                badge: "Anonymous"
            )
        }
    }
    
    // MARK: - Safety Content
    
    private var safetyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Safety Planning")
                .font(.title2)
                .fontWeight(.bold)
            
            safetyCard(
                icon: "checklist",
                title: "Safety Checklist",
                description: "Step-by-step safety planning guide"
            )
            
            safetyCard(
                icon: "bag.fill",
                title: "Emergency Bag",
                description: "Essential items to have ready"
            )
            
            safetyCard(
                icon: "phone.arrow.up.right.fill",
                title: "Emergency Contacts",
                description: "Set up your emergency contact network"
            )
            
            safetyCard(
                icon: "location.fill",
                title: "Safe Places",
                description: "Identify and document safe locations"
            )
        }
    }
    
    // MARK: - Card Views
    
    private func educationCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.voiceitPurple)
                .frame(width: 50, height: 50)
                .background(Color.voiceitPurple.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func supportCard(icon: String, title: String, description: String, badge: String? = nil) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.voiceitPurple)
                .frame(width: 50, height: 50)
                .background(Color.voiceitPurple.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.voiceitSuccess)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func safetyCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.voiceitPurple)
                .frame(width: 50, height: 50)
                .background(Color.voiceitPurple.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - Community Section

enum CommunitySection: String, CaseIterable {
    case education = "Education"
    case support = "Support"
    case safety = "Safety"
}

#Preview {
    CommunityView()
}
