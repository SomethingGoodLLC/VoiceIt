import SwiftUI

/// Privacy-first onboarding with authentication setup
struct OnboardingView: View {
    // MARK: - Properties
    
    @Binding var isAuthenticated: Bool
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var currentPage = 0
    @State private var showingAuthSetup = false
    @State private var showingEmergencyContactsSetup = false
    @State private var showingSafetyPlan = false
    
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    
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
                    
                    safetyPlanPage
                        .tag(4)
                    
                    emergencyContactsPage
                        .tag(5)
                    
                    stealthModePage
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Continue button
                Button {
                    if currentPage < 6 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        showingAuthSetup = true
                    }
                } label: {
                    Text(currentPage < 6 ? "Continue" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                }
                .padding()
                
                // Skip button for later pages
                if currentPage >= 4 {
                    Button("Skip for Now") {
                        if currentPage < 6 {
                            withAnimation {
                                currentPage = 6
                            }
                        } else {
                            showingAuthSetup = true
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showingAuthSetup) {
            AuthenticationSetupView(isAuthenticated: $isAuthenticated, hasCompletedOnboarding: $hasCompletedOnboarding)
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
    
    // MARK: - Safety Plan Page
    
    private var safetyPlanPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 100))
                .foregroundStyle(.white)
            
            Text("Safety Planning")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Creating a safety plan helps you prepare for emergencies and stay safe")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                safetyPlanItem(icon: "person.2.fill", text: "Identify trusted contacts")
                safetyPlanItem(icon: "location.fill", text: "Plan safe locations")
                safetyPlanItem(icon: "bag.fill", text: "Prepare emergency bag")
                safetyPlanItem(icon: "doc.text.fill", text: "Document evidence safely")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Emergency Contacts Page
    
    private var emergencyContactsPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 100))
                .foregroundStyle(.white)
            
            Text("Emergency Contacts")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Set up trusted contacts who can receive alerts during emergencies")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                emergencyContactFeature(icon: "phone.fill", text: "Quick call access")
                emergencyContactFeature(icon: "message.fill", text: "Automatic SMS alerts")
                emergencyContactFeature(icon: "bell.fill", text: "Panic button integration")
            }
            .padding(.horizontal)
            
            Button {
                showingEmergencyContactsSetup = true
            } label: {
                Text("Set Up Now")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingEmergencyContactsSetup) {
            EmergencyContactsView()
        }
    }
    
    // MARK: - Stealth Mode Page
    
    private var stealthModePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 100))
                .foregroundStyle(.white)
            
            Text("Stealth Mode")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Hide the app instantly with decoy screens for added safety")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                stealthFeature(icon: "hand.raised.fill", text: "Shake device to hide")
                stealthFeature(icon: "faceid", text: "Unlock with Face ID/Touch ID")
                stealthFeature(icon: "app.badge", text: "Calculator & weather disguises")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helper Views for New Pages
    
    private func safetyPlanItem(icon: String, text: String) -> some View {
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
    
    private func emergencyContactFeature(icon: String, text: String) -> some View {
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
    
    private func stealthFeature(icon: String, text: String) -> some View {
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
    @Binding var hasCompletedOnboarding: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authenticationService) private var authService
    
    @State private var setupStep: SetupStep = .choose
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var errorMessage = ""
    @FocusState private var isPasscodeFieldFocused: Bool
    
    enum SetupStep {
        case choose
        case enterPasscode
        case confirmPasscode
        case enableBiometrics
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voiceitGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Icon
                    Image(systemName: iconForStep)
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    // Title
                    Text(titleForStep)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    // Subtitle
                    Text(subtitleForStep)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Content for each step
                    contentForStep
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.white)
                            .font(.caption)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var contentForStep: some View {
        switch setupStep {
        case .choose:
            chooseSecurityOptions
        case .enterPasscode:
            passcodeEntryView
        case .confirmPasscode:
            passcodeConfirmView
        case .enableBiometrics:
            biometricsView
        }
    }
    
    private var chooseSecurityOptions: some View {
        VStack(spacing: 16) {
            // Set up passcode button
            Button {
                setupStep = .enterPasscode
                errorMessage = ""
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                    Text("Set Up Passcode")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }
            
            // Enable biometrics (if available)
            if authService.biometricType != .none {
                Button {
                    setupStep = .enableBiometrics
                    errorMessage = ""
                } label: {
                    HStack {
                        Image(systemName: authService.biometricType.icon)
                            .font(.title2)
                        Text("Enable \(authService.biometricType.displayName)")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                }
            }
            
            // Skip button
            Button {
                isAuthenticated = true
                hasCompletedOnboarding = true
                dismiss()
            } label: {
                Text("Skip (Not Recommended)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 8)
        }
    }
    
    private var passcodeEntryView: some View {
        VStack(spacing: 20) {
            // Passcode input
            SecureField("Enter 6-digit passcode", text: $passcode)
                .textContentType(.newPassword)
                .keyboardType(.numberPad)
                .font(.title3)
                .foregroundStyle(.white)
                .padding()
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isPasscodeFieldFocused)
                .onChange(of: passcode) { oldValue, newValue in
                    // Limit to numbers only
                    passcode = newValue.filter { $0.isNumber }
                    // Auto-advance when 6 digits entered
                    if passcode.count == 6 {
                        setupStep = .confirmPasscode
                        errorMessage = ""
                    }
                }
            
            // Requirements
            VStack(alignment: .leading, spacing: 8) {
                requirementRow(met: passcode.count >= 6, text: "At least 6 digits")
                requirementRow(met: passcode.allSatisfy { $0.isNumber }, text: "Numbers only")
            }
            .padding(.horizontal)
            
            // Back button
            Button {
                setupStep = .choose
                passcode = ""
                errorMessage = ""
            } label: {
                Text("Back")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .onAppear {
            isPasscodeFieldFocused = true
        }
    }
    
    private var passcodeConfirmView: some View {
        VStack(spacing: 20) {
            // Confirm passcode input
            SecureField("Confirm passcode", text: $confirmPasscode)
                .textContentType(.newPassword)
                .keyboardType(.numberPad)
                .font(.title3)
                .foregroundStyle(.white)
                .padding()
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isPasscodeFieldFocused)
                .onChange(of: confirmPasscode) { oldValue, newValue in
                    confirmPasscode = newValue.filter { $0.isNumber }
                    if confirmPasscode.count == 6 {
                        savePasscode()
                    }
                }
            
            // Match indicator
            if confirmPasscode.count > 0 {
                HStack(spacing: 8) {
                    Image(systemName: confirmPasscode == passcode ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(confirmPasscode == passcode ? .green : .red)
                    Text(confirmPasscode == passcode ? "Passcodes match" : "Passcodes don't match")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
            
            // Back button
            Button {
                setupStep = .enterPasscode
                confirmPasscode = ""
                errorMessage = ""
            } label: {
                Text("Back")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .onAppear {
            isPasscodeFieldFocused = true
        }
    }
    
    private var biometricsView: some View {
        VStack(spacing: 20) {
            Button {
                Task {
                    await enableBiometrics()
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
            
            Button {
                // Complete without biometrics
                isAuthenticated = true
                hasCompletedOnboarding = true
                dismiss()
            } label: {
                Text("Skip Biometrics")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func requirementRow(met: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? .green : .white.opacity(0.5))
            Text(text)
                .font(.caption)
                .foregroundStyle(.white)
        }
    }
    
    private var iconForStep: String {
        switch setupStep {
        case .choose:
            return "lock.shield.fill"
        case .enterPasscode, .confirmPasscode:
            return "key.fill"
        case .enableBiometrics:
            return authService.biometricType.icon
        }
    }
    
    private var titleForStep: String {
        switch setupStep {
        case .choose:
            return "Set Up Security"
        case .enterPasscode:
            return "Create Passcode"
        case .confirmPasscode:
            return "Confirm Passcode"
        case .enableBiometrics:
            return "Enable Biometrics"
        }
    }
    
    private var subtitleForStep: String {
        switch setupStep {
        case .choose:
            return "Protect your evidence with a passcode or biometric authentication"
        case .enterPasscode:
            return "Enter a 6-digit passcode"
        case .confirmPasscode:
            return "Re-enter your passcode to confirm"
        case .enableBiometrics:
            return "Use \(authService.biometricType.displayName) for quick and secure access"
        }
    }
    
    // MARK: - Actions
    
    private func savePasscode() {
        guard passcode == confirmPasscode else {
            errorMessage = "Passcodes don't match"
            return
        }
        
        guard passcode.count >= 6 else {
            errorMessage = "Passcode must be at least 6 digits"
            return
        }
        
        do {
            try authService.setPasscode(passcode)
            errorMessage = ""
            
            // Move to biometrics if available, otherwise complete
            if authService.biometricType != .none {
                setupStep = .enableBiometrics
            } else {
                isAuthenticated = true
                hasCompletedOnboarding = true
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func enableBiometrics() async {
        do {
            try await authService.authenticate()
            authService.isBiometricEnabled = true
            isAuthenticated = true
            hasCompletedOnboarding = true
            dismiss()
        } catch {
            errorMessage = "Failed to enable biometrics: \(error.localizedDescription)"
        }
    }
}

#Preview {
    OnboardingView(isAuthenticated: .constant(false), hasCompletedOnboarding: .constant(false))
}
