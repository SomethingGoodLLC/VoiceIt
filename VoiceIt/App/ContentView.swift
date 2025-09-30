import SwiftUI

/// Main tab container for the Voice It app
struct ContentView: View {
    // MARK: - Properties
    
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    @State private var showingOnboarding = true
    @State private var showPanicButton = true
    
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    @Environment(\.emergencyService) private var emergencyService
    @Environment(\.locationService) private var locationService
    @Environment(\.audioRecordingService) private var audioRecordingService
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if !isAuthenticated {
                OnboardingView(isAuthenticated: $isAuthenticated, showingOnboarding: $showingOnboarding)
            } else {
                StealthModeContainerView(stealthService: stealthService) {
                    mainContentWithPanicButton
                }
            }
        }
    }
    
    // MARK: - Main Content with Panic Button
    
    private var mainContentWithPanicButton: some View {
        ZStack {
            mainTabView
            
            // Panic button overlay
            if showPanicButton {
                PanicButtonView(
                    stealthService: stealthService,
                    emergencyService: emergencyService,
                    locationService: locationService,
                    audioRecordingService: audioRecordingService
                )
            }
        }
        .onShake {
            // Quick hide on shake gesture
            stealthService.quickHide()
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
            
            NavigationStack {
                List {
                    Section {
                        NavigationLink {
                            EmergencyContactsView()
                        } label: {
                            Label("Emergency Contacts", systemImage: "person.crop.circle.badge.exclamationmark")
                                .foregroundColor(.red)
                        }
                        
                        NavigationLink {
                            StealthModeSettingsView(stealthService: stealthService)
                        } label: {
                            Label("Stealth Mode Settings", systemImage: "eye.slash.fill")
                        }
                    } header: {
                        Text("Safety Features")
                    }
                    
                    Section {
                        Toggle("Show Panic Button", isOn: $showPanicButton)
                        
                        Toggle("Call 911 on Panic", isOn: Binding(
                            get: { emergencyService.shouldCall911 },
                            set: { emergencyService.shouldCall911 = $0 }
                        ))
                    } header: {
                        Text("Emergency")
                    } footer: {
                        Text("When disabled, panic button will only send SMS alerts to emergency contacts without calling 911.")
                    }
                    
                    Section {
                        CommunityView()
                    } header: {
                        Text("Community")
                    }
                }
                .navigationTitle("More")
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle.fill")
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
