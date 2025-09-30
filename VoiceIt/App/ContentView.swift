import SwiftUI

/// Main tab container for the Voice It app
struct ContentView: View {
    // MARK: - Properties
    
    @State private var selectedTab = 0
    @State private var isAuthenticated = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showPanicButton = true
    
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    @Environment(\.emergencyService) private var emergencyService
    @Environment(\.locationService) private var locationService
    @Environment(\.audioRecordingService) private var audioRecordingService
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // Show onboarding only once
                OnboardingView(isAuthenticated: $isAuthenticated, hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if !isAuthenticated {
                // Show authentication if onboarding is done but not authenticated
                authenticationPrompt
            } else {
                // Show main app content
                StealthModeContainerView(stealthService: stealthService) {
                    mainContentWithPanicButton
                }
            }
        }
    }
    
    // MARK: - Authentication Prompt
    
    private var authenticationPrompt: some View {
        ZStack {
            Color.voiceitGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: authService.biometricType.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Authenticate to access your evidence")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button {
                    Task {
                        do {
                            if authService.biometricType != .none {
                                try await authService.authenticate()
                                isAuthenticated = true
                            } else {
                                // No biometrics available, just let them in
                                isAuthenticated = true
                            }
                        } catch {
                            print("Authentication failed: \(error)")
                        }
                    }
                } label: {
                    Label(authService.biometricType != .none ? "Authenticate with \(authService.biometricType.displayName)" : "Continue",
                          systemImage: authService.biometricType.icon)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
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
