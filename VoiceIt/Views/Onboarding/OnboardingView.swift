import SwiftUI

/// Privacy-first onboarding with authentication setup
struct OnboardingView: View {
    // MARK: - Properties
    
    @Binding var isAuthenticated: Bool
    @Binding var showingOnboarding: Bool
    
    @State private var currentPage = 0
    @State private var showingAuthSetup = false
    
    @Environment(\.authenticationService) private var authService
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            Color.voiceitGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    welcomePage
                        .tag(0)
                    
                    privacyPage
                        .tag(1)
                    
                    securityPage
                        .tag(2)
                    
                    permissionsPage
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Continue button
                Button {
                    if currentPage < 3 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        showingAuthSetup = true
                    }
                } label: {
                    Text(currentPage < 3 ? "Continue" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingAuthSetup) {
            AuthenticationSetupView(isAuthenticated: $isAuthenticated, showingOnboarding: $showingOnboarding)
        }
    }
    
    // MARK: - Welcome Page
    
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "shield.checkered")
                .font(.system(size: 100))
                .foregroundStyle(.white)
            
            Text("Welcome to Voice It")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("A safe, private space to document and protect evidence")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Privacy Page
    
    private var privacyPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 100))
                .foregroundStyle(.white)
            
            Text("Your Privacy Matters")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 20) {
                privacyFeature(icon: "iphone", text: "All data stays on your device")
                privacyFeature(icon: "key.fill", text: "End-to-end encryption")
                privacyFeature(icon: "eye.slash.fill", text: "No cloud storage or tracking")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Security Page
    
    private var securityPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: authService.biometricType.icon)
                .font(.system(size: 100))
                .foregroundStyle(.white)
            
            Text("Secure Access")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 20) {
                if authService.biometricType != .none {
                    securityFeature(icon: authService.biometricType.icon, text: "\(authService.biometricType.displayName) authentication")
                } else {
                    securityFeature(icon: "lock.fill", text: "Secure passcode protection")
                }
                securityFeature(icon: "timer", text: "Auto-lock after inactivity")
                securityFeature(icon: "shield.checkered", text: "End-to-end encryption")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Permissions Page
    
    private var permissionsPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 100))
                .foregroundStyle(.white)
            
            Text("Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("We'll ask for permissions as needed:")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                permissionItem(icon: "mic.fill", text: "Microphone (for voice notes)")
                permissionItem(icon: "camera.fill", text: "Camera (for photos/videos)")
                permissionItem(icon: "location.fill", text: "Location (optional tracking)")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func privacyFeature(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 30)
            
            Text(text)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
    
    private func securityFeature(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 30)
            
            Text(text)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
    
    private func permissionItem(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 30)
            
            Text(text)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Authentication Setup View

struct AuthenticationSetupView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showingOnboarding: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authenticationService) private var authService
    
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voiceitGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Image(systemName: authService.biometricType.icon)
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("Set Up Security")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    if authService.biometricType != .none {
                        Button {
                            Task {
                                do {
                                    try await authService.authenticate()
                                    isAuthenticated = true
                                    showingOnboarding = false
                                    dismiss()
                                } catch {
                                    errorMessage = "Authentication failed"
                                }
                            }
                        } label: {
                            Label("Enable \(authService.biometricType.displayName)", systemImage: authService.biometricType.icon)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                        }
                    }
                    
                    Button {
                        // Skip for now (not recommended)
                        isAuthenticated = true
                        showingOnboarding = false
                        dismiss()
                    } label: {
                        Text("Skip (Not Recommended)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    OnboardingView(isAuthenticated: .constant(false), showingOnboarding: .constant(true))
}
