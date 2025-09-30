import SwiftUI

/// Community hub - Privacy-first support, therapy, legal help, and resources
@available(iOS 18, *)
struct CommunityView: View {
    @Environment(\.communityService) private var communityService
    @State private var showPrivacySettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Privacy Notice
                    privacyNotice
                    
                    // Main Features
                    featuresGrid
                    
                    // Quick Stats
                    if hasActiveBookings {
                        quickStatsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPrivacySettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showPrivacySettings) {
                PrivacySettingsView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.voiceitPurple, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("You Are Not Alone")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Connect with support, professionals, and resources")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var privacyNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Privacy is Protected")
                        .font(.headline)
                    
                    Text("All interactions are confidential and end-to-end encrypted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if communityService.isAnonymousModeEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundStyle(.green)
                    
                    Text("Anonymous Mode: \(communityService.myPseudonym)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var featuresGrid: some View {
        VStack(spacing: 16) {
            // Support Groups
            NavigationLink {
                SupportGroupsListView()
            } label: {
                FeatureCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Anonymous Support Groups",
                    description: "Join moderated discussions with others who understand",
                    badge: "Anonymous",
                    badgeColor: .green,
                    gradient: [Color.purple, Color.blue]
                )
            }
            .buttonStyle(.plain)
            
            // Free Therapy
            NavigationLink {
                TherapyListView()
            } label: {
                FeatureCard(
                    icon: "heart.text.square.fill",
                    title: "Free Therapy Sessions",
                    description: "Book 30-min video sessions with licensed therapists",
                    badge: "Pro Bono",
                    badgeColor: .pink,
                    gradient: [Color.pink, Color.orange]
                )
            }
            .buttonStyle(.plain)
            
            // Legal Consultations
            NavigationLink {
                LawyersListView()
            } label: {
                FeatureCard(
                    icon: "hammer.circle.fill",
                    title: "Legal Consultations",
                    description: "Connect with pro bono lawyers for initial consultations",
                    badge: "Confidential",
                    badgeColor: .blue,
                    gradient: [Color.blue, Color.cyan]
                )
            }
            .buttonStyle(.plain)
            
            // Resource Library
            NavigationLink {
                ResourceLibraryView()
            } label: {
                FeatureCard(
                    icon: "book.circle.fill",
                    title: "Resource Library",
                    description: "Articles, videos, guides, and downloadable checklists",
                    badge: "\(communityService.articles.count) Resources",
                    badgeColor: .orange,
                    gradient: [Color.orange, Color.yellow]
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var hasActiveBookings: Bool {
        !communityService.myTherapySessions.isEmpty || !communityService.myConsultations.isEmpty
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Activity")
                .font(.headline)
            
            HStack(spacing: 16) {
                if !communityService.myTherapySessions.isEmpty {
                    StatCard(
                        icon: "calendar",
                        title: "Sessions",
                        count: communityService.myTherapySessions.count,
                        color: .pink
                    )
                }
                
                if !communityService.myConsultations.isEmpty {
                    StatCard(
                        icon: "briefcase",
                        title: "Consultations",
                        count: communityService.myConsultations.count,
                        color: .blue
                    )
                }
            }
        }
    }
}

/// Feature card component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let badge: String
    let badgeColor: Color
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Spacer()
                
                Text(badge)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(badgeColor.opacity(0.2))
                    .foregroundStyle(badgeColor)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("Explore")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(gradient[0])
                
                Image(systemName: "arrow.right")
                    .font(.subheadline)
                    .foregroundStyle(gradient[0])
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

/// Stat card component
struct StatCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Privacy settings view
@available(iOS 18, *)
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.communityService) private var communityService
    
    @State private var showDeleteConfirmation = false
    @State private var isAnonymousMode = true
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Anonymous Mode", isOn: Binding(
                        get: { communityService.isAnonymousModeEnabled },
                        set: { communityService.isAnonymousModeEnabled = $0 }
                    ))
                    
                    if communityService.isAnonymousModeEnabled {
                        HStack {
                            Text("Your Pseudonym")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(communityService.myPseudonym)
                                .fontWeight(.medium)
                        }
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("When enabled, you'll appear as '\(communityService.myPseudonym)' in support groups and discussions.")
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete My Activity", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This will permanently delete all your community posts, messages, and generate a new pseudonym.")
                }
                
                Section {
                    HStack {
                        Text("End-to-End Encryption")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Text("No Analytics Tracking")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Text("Local-First Storage")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Security Features")
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Activity?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    communityService.deleteMyActivity()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete all your community activity and cannot be undone.")
            }
        }
    }
}

#Preview {
    CommunityView()
        .environment(\.communityService, CommunityService())
}