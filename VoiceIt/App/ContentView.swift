import SwiftUI

/// Main tab container for the Voice It app
struct ContentView: View {
    // MARK: - Properties
    
    // DEMO MODE: Set to true to bypass authentication for demos
    // Set back to false before shipping!
    #if DEBUG
    private let demoMode = false
    #else
    private let demoMode = false
    #endif
    
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showPanicButton = true
    
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    @Environment(\.emergencyService) private var emergencyService
    @Environment(\.locationService) private var locationService
    @Environment(\.audioRecordingService) private var audioRecordingService
    @Environment(\.scenePhase) private var scenePhase
    
    private let apiService = APIService.shared
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding && !demoMode {
                // Show onboarding only once (skip in demo mode)
                OnboardingView(isAuthenticated: $isAuthenticated, hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if stealthService.isStealthActive && !demoMode {
                // The disguised decoy is the only lock screen. Unlocking happens from
                // within the decoy via biometric/passcode. Launches locked-by-default.
                StealthModeContainerView(stealthService: stealthService, onUnlock: {
                    // When unlocked from stealth mode, mark as authenticated
                    isAuthenticated = true
                    // Sync with auth service state
                    authService.isAuthenticated = true
                }) {
                    Color.clear // Placeholder
                }
            } else {
                // Normal app with tabs and panic button
                mainContentWithPanicButton
            }
        }
        .onChange(of: stealthService.isStealthActive) { oldValue, newValue in
            // When stealth mode is deactivated, authenticate the user
            if oldValue == true && newValue == false {
                isAuthenticated = true
                authService.isAuthenticated = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Reset authentication only on true background (not transient inactive)
            if newPhase == .background {
                isAuthenticated = false
            }
            
            // Track app open when user brings app to foreground (skip in demo mode)
            if newPhase == .active && apiService.isAuthenticated && !demoMode {
                apiService.trackAppOpen()
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
            
            // Transient privacy overlay during brief inactive states (Control Center, etc.)
            if stealthService.isPrivacyShieldVisible && !stealthService.isStealthActive {
                DecoyScreenView(decoyType: stealthService.decoyScreen)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: stealthService.isPrivacyShieldVisible)
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
            
            if #available(iOS 18, *) {
                CommunityView()
                    .tabItem {
                        Label("Community", systemImage: "person.3.fill")
                    }
                    .tag(3)
            }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
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