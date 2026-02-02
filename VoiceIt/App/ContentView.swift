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
    @State private var showPanicButton = false
    
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
            } else if !isAuthenticated && !demoMode {
                // Show authentication if onboarding is done but not authenticated (skip in demo mode)
                authenticationPrompt
            } else {
                // Show main app content with stealth mode wrapper
                if stealthService.isStealthActive {
                    // Fullscreen stealth mode (no tabs visible)
                    StealthModeContainerView(stealthService: stealthService) {
                        Color.clear // Placeholder, stealth container shows decoy
                    }
                } else {
                    // Normal app with tabs and panic button
                    mainContentWithPanicButton
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Track app open when user brings app to foreground (skip in demo mode)
            if newPhase == .active && (isAuthenticated || demoMode) && apiService.isAuthenticated && !demoMode {
                apiService.trackAppOpen()
            }
            
            // Lock the app when it goes to background/inactive
            if newPhase == .background {
                // Ensure the decoy screen is shown next time
                isAuthenticated = false
                stealthService.isStealthActive = true
            }
        }
    }
    
    // MARK: - Authentication Prompt
    
    @ViewBuilder
    private var authenticationPrompt: some View {
        // Show decoy screen directly as the lock screen
        DecoyLockScreenView(
            isAuthenticated: $isAuthenticated,
            stealthService: stealthService,
            authService: authService
        )
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

// MARK: - Decoy Lock Screen View

private struct DecoyLockScreenView: View {
    @Binding var isAuthenticated: Bool
    @Bindable var stealthService: StealthModeService
    let authService: AuthenticationService
    
    var body: some View {
        Group {
            // Show decoy screen based on selected type
            switch stealthService.decoyScreen {
            case .calculator:
                CalculatorDecoyView()
                    .environment(\.authenticationService, authService)
                    .environment(\.stealthModeService, stealthService)
            case .weather:
                WeatherDecoyView()
                    .environment(\.authenticationService, authService)
                    .environment(\.stealthModeService, stealthService)
            case .notes:
                NotesDecoyView()
                    .environment(\.authenticationService, authService)
                    .environment(\.stealthModeService, stealthService)
            case .crossStitch:
                CrossStitchDecoyView()
                    .environment(\.authenticationService, authService)
                    .environment(\.stealthModeService, stealthService)
            }
        }
        .onChange(of: stealthService.isStealthActive) { oldValue, newValue in
            if !newValue && !isAuthenticated {
                // Decoy was unlocked, authenticate the user
                isAuthenticated = true
            }
        }
        .onAppear {
            // Ensure stealth mode is active so decoy shows
            stealthService.isStealthActive = true
        }
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
