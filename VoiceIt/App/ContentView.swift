import SwiftUI

/// Main tab container for the Voice It app
struct ContentView: View {
    // MARK: - Properties
    
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    @State private var showingOnboarding = true
    
    @Environment(\.authenticationService) private var authService
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if !isAuthenticated {
                OnboardingView(isAuthenticated: $isAuthenticated, showingOnboarding: $showingOnboarding)
            } else {
                mainTabView
            }
        }
    }
    
    // MARK: - Main Tab View
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "clock.fill")
                }
                .tag(0)
            
            AddEvidenceView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            ResourcesView()
                .tabItem {
                    Label("Resources", systemImage: "heart.circle.fill")
                }
                .tag(2)
            
            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.2.fill")
                }
                .tag(3)
        }
        .tint(.voiceitPurple)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            VoiceNote.self,
            PhotoEvidence.self,
            VideoEvidence.self,
            TextEntry.self,
            LocationSnapshot.self,
            EmergencyContact.self,
            Resource.self
        ], inMemory: true)
}
