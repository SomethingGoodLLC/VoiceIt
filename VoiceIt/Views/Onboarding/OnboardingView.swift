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
    @State private var showingEmailSignup = false
    
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
                        // After last onboarding page, show email signup (REQUIRED)
                        showingEmailSignup = true
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
                
                // Skip button for middle pages (4-5) only - NOT on the last page (6)
                // Email signup is MANDATORY before proceeding
                if currentPage >= 4 && currentPage < 6 {
                    Button("Skip for Now") {
                        withAnimation {
                            currentPage = 6
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showingEmailSignup) {
            EmailSignupView(
                isAuthenticated: $isAuthenticated,
                hasCompletedOnboarding: $hasCompletedOnboarding,
                showingAuthSetup: $showingAuthSetup
            )
            .interactiveDismissDisabled() // CRITICAL: Email signup is MANDATORY - cannot be dismissed
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

// MARK: - Email Signup View (Required Step)

struct EmailSignupView: View {
    @Binding var isAuthenticated: Bool
    @Binding var hasCompletedOnboarding: Bool
    @Binding var showingAuthSetup: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoginMode = false // Switch between login and signup
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?
    
    private let apiService = APIService.shared
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voiceitGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: isLoginMode ? "person.circle.fill" : "envelope.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.white)
                            
                            Text(isLoginMode ? "Welcome Back" : "Create Your Account")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text(isLoginMode ? "Log in to access your account" : "Sign up to get started")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Toggle between login and signup (TOP POSITION)
                            Button {
                                withAnimation {
                                    isLoginMode.toggle()
                                    confirmPassword = ""
                                    errorMessage = ""
                                }
                            } label: {
                                Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.white.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.top, 20)
                        
                        // Form fields
                        VStack(spacing: 16) {
                            // Name field (optional) - only for signup
                            if !isLoginMode {
                                TextField("Name (optional)", text: $name)
                                    .textContentType(.name)
                                    .onboardingTextFieldStyle()
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .email }
                            }
                            
                            // Email field
                            TextField("Email", text: $email)
                                .textContentType(isLoginMode ? .emailAddress : .emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .onboardingTextFieldStyle()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                            
                            // Password field
                            SecureField(isLoginMode ? "Password" : "Password (min 6 characters)", text: $password)
                                .textContentType(isLoginMode ? .password : .newPassword)
                                .onboardingTextFieldStyle()
                                .focused($focusedField, equals: .password)
                                .submitLabel(isLoginMode ? .done : .next)
                                .onSubmit {
                                    if isLoginMode {
                                        handleAuth()
                                    } else {
                                        focusedField = .confirmPassword
                                    }
                                }
                            
                            // Confirm password field - only for signup
                            if !isLoginMode {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .onboardingTextFieldStyle()
                                    .focused($focusedField, equals: .confirmPassword)
                                    .submitLabel(.done)
                                    .onSubmit { handleAuth() }
                                
                                // Password match indicator
                                if !confirmPassword.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(password == confirmPassword ? .green : .red)
                                        Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            
                            // Requirements
                            if !isLoginMode {
                                VStack(alignment: .leading, spacing: 8) {
                                    requirementRow(met: !email.isEmpty && email.contains("@"), text: "Valid email address")
                                    requirementRow(met: password.count >= 6, text: "At least 6 characters")
                                    requirementRow(met: password == confirmPassword && !password.isEmpty, text: "Passwords match")
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Privacy note
                        if !isLoginMode {
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text("Your evidence stays encrypted on your device. Your email is only used for account management.")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding()
                                .background(.white.opacity(0.15))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Action button (Login or Create Account)
                        Button {
                            handleAuth()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isLoginMode ? "Log In" : "Create Account")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? .white.opacity(0.25) : .white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(!isFormValid || isLoading)
                        .padding(.horizontal)
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundStyle(.white)
                                .font(.caption)
                                .padding()
                                .background(.red.opacity(0.3))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helpers
    
    private var isFormValid: Bool {
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 6
        
        if isLoginMode {
            // For login, just need email and password
            return emailValid && !password.isEmpty
        } else {
            // For signup, need password confirmation too
            return emailValid && passwordValid && password == confirmPassword
        }
    }
    
    private func requirementRow(met: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? .green : .white.opacity(0.5))
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Actions
    
    private func handleAuth() {
        guard isFormValid else { return }
        
        Task {
            isLoading = true
            errorMessage = ""
            
            do {
                let response: AuthResponse
                
                if isLoginMode {
                    // Login existing user
                    response = try await apiService.login(email: email, password: password)
                } else {
                    // Sign up new user
                    response = try await apiService.signUp(
                        email: email,
                        password: password,
                        name: name.isEmpty ? nil : name
                    )
                }
                
                if response.success {
                    // Success - dismiss email signup and show authentication setup
                    await MainActor.run {
                        dismiss()
                        // Small delay to allow sheet to dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingAuthSetup = true
                        }
                    }
                } else {
                    errorMessage = response.message ?? (isLoginMode ? "Login failed. Please try again." : "Signup failed. Please try again.")
                }
            } catch {
                errorMessage = "Network error: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}

// MARK: - Text Field Style

private struct OnboardingTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white.opacity(0.2))
            .foregroundStyle(.white)
            .cornerRadius(12)
            .tint(.white)
    }
}

private extension View {
    func onboardingTextFieldStyle() -> some View {
        modifier(OnboardingTextFieldStyle())
    }
}

#Preview {
    OnboardingView(isAuthenticated: .constant(false), hasCompletedOnboarding: .constant(false))
}
