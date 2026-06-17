import SwiftUI

/// Privacy-first onboarding with authentication setup
struct OnboardingView: View {
    // MARK: - Properties
    
    @Binding var isAuthenticated: Bool
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var currentPage = 0
    @State private var showingStealthWalkthrough = false
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
                    
                    stealthModePage
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Continue button
                Button {
                    if currentPage < 5 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // After last onboarding page, show email signup (REQUIRED)
                        showingEmailSignup = true
                    }
                } label: {
                    Text(currentPage < 5 ? "Continue" : "Get Started")
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
        .sheet(isPresented: $showingEmailSignup) {
            EmailSignupView(
                isAuthenticated: $isAuthenticated,
                hasCompletedOnboarding: $hasCompletedOnboarding,
                showingStealthWalkthrough: $showingStealthWalkthrough
            )
            .interactiveDismissDisabled() // CRITICAL: Email signup is MANDATORY - cannot be dismissed
        }
        .sheet(isPresented: $showingStealthWalkthrough) {
            StealthWalkthroughView(isAuthenticated: $isAuthenticated, hasCompletedOnboarding: $hasCompletedOnboarding)
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
                stealthFeature(icon: "eye.fill", text: "Tap the eye icon to hide instantly")
                stealthFeature(icon: "eye.slash", text: "Disguised as Calculator, Notes, or Cross Stitch")
                stealthFeature(icon: "faceid", text: "Long-press (1.5 sec) anywhere to unlock with Face ID")
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

// MARK: - Stealth Walkthrough View

struct StealthWalkthroughView: View {
    @Binding var isAuthenticated: Bool
    @Binding var hasCompletedOnboarding: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.stealthModeService) private var stealthService
    @Environment(\.authenticationService) private var authService
    
    @State private var currentStep = 0
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var passcodeError: String?
    @State private var passcodeSet = false
    @State private var appIconService = AppIconService.shared
    
    // Whether biometrics are available
    private var needsPasscode: Bool {
        authService.biometricType == .none
    }
    
    // Total steps: 3 if biometrics available, 4 if passcode needed
    private var totalSteps: Int {
        needsPasscode ? 4 : 3
    }
    
    private var lastStepIndex: Int {
        totalSteps - 1
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voiceitGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Content based on step
                    TabView(selection: $currentStep) {
                        stealthIntroView.tag(0)
                        decoySelectionView.tag(1)
                        
                        if needsPasscode {
                            passcodeSetupView.tag(2)
                            unlockView.tag(3)
                        } else {
                            unlockView.tag(2)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    // Continue Button
                    Button {
                        handleContinue()
                    } label: {
                        Text(continueButtonText)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white.opacity(continueButtonEnabled ? 0.2 : 0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                    }
                    .disabled(!continueButtonEnabled)
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Only allow skip if biometrics are available (they can use Face ID to unlock)
                    if !needsPasscode && currentStep < lastStepIndex {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
        }
    }
    
    private var continueButtonText: String {
        if currentStep == lastStepIndex {
            return "Finish Setup"
        } else if needsPasscode && currentStep == 2 && !passcodeSet {
            return "Set Passcode"
        } else {
            return "Next"
        }
    }
    
    private var continueButtonEnabled: Bool {
        // On passcode step, require valid passcode before continuing
        if needsPasscode && currentStep == 2 && !passcodeSet {
            return passcode.count >= 6 && passcode == confirmPasscode && passcode.allSatisfy { $0.isNumber }
        }
        return true
    }
    
    private func handleContinue() {
        // Special handling for passcode step
        if needsPasscode && currentStep == 2 && !passcodeSet {
            savePasscode()
            return
        }
        
        if currentStep < lastStepIndex {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func savePasscode() {
        guard passcode.count >= 6,
              passcode == confirmPasscode,
              passcode.allSatisfy({ $0.isNumber }) else {
            passcodeError = "Please enter matching 6+ digit passcodes"
            return
        }
        
        do {
            try authService.setPasscode(passcode)
            passcodeSet = true
            passcodeError = nil
            HapticService.shared.success()
            
            // Move to next step
            withAnimation {
                currentStep += 1
            }
        } catch {
            passcodeError = error.localizedDescription
            HapticService.shared.error()
        }
    }
    
    // MARK: - Steps
    
    private var stealthIntroView: some View {
        VStack(spacing: 30) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white)
            
            Text("Hide in Plain Sight")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("Voice It is designed to protect your privacy. Learn how to instantly hide the app in an emergency.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var decoySelectionView: some View {
        VStack(spacing: 30) {
            Text("Choose Your Disguise")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("When you hide the app, it will look like one of these:")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                ForEach(DecoyScreenType.allCases, id: \.self) { type in
                    Button {
                        stealthService.setDecoyScreen(type)
                        // Also change the app icon to match the selected decoy
                        changeIconToMatch(type)
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .frame(width: 40)
                            
                            Text(type.displayName)
                                .font(.headline)
                            
                            Spacer()
                            
                            if stealthService.decoyScreen == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(.white.opacity(stealthService.decoyScreen == type ? 0.3 : 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func changeIconToMatch(_ decoy: DecoyScreenType) {
        Task {
            let appIcon = AppIcon.forDecoy(decoy)
            
            do {
                try await appIconService.changeIcon(to: appIcon)
            } catch {
                // Silently fail - icon change is a nice-to-have during onboarding
                print("Failed to change app icon during onboarding: \(error.localizedDescription)")
            }
        }
    }
    
    private var passcodeSetupView: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)
            
            Text("Set Your Passcode")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("Since Face ID isn't available, you'll need a passcode to unlock the app from stealth mode.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                SecureField("Enter 6+ digit passcode", text: $passcode)
                    .keyboardType(.numberPad)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.white.opacity(0.2))
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .tint(.white)
                
                SecureField("Confirm passcode", text: $confirmPasscode)
                    .keyboardType(.numberPad)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.white.opacity(0.2))
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .tint(.white)
                
                // Validation indicators
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: passcode.count >= 6 ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(passcode.count >= 6 ? .green : .white.opacity(0.5))
                        Text("At least 6 digits")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: passcode.allSatisfy { $0.isNumber } && !passcode.isEmpty ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(passcode.allSatisfy { $0.isNumber } && !passcode.isEmpty ? .green : .white.opacity(0.5))
                        Text("Numbers only")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: passcode == confirmPasscode && !passcode.isEmpty ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(passcode == confirmPasscode && !passcode.isEmpty ? .green : .white.opacity(0.5))
                        Text("Passcodes match")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                
                if let error = passcodeError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .background(.red.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var unlockView: some View {
        VStack(spacing: 24) {
            Image(systemName: authService.biometricType == .none ? "lock.open.fill" : authService.biometricType.icon)
                .font(.system(size: 60))
                .foregroundStyle(.white)
            
            Text("How to Unlock")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("When the decoy is showing:")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                // Biometric unlock (if available)
                if authService.biometricType != .none {
                    unlockMethodRow(
                        icon: authService.biometricType.icon,
                        title: "\(authService.biometricType.displayName) (Recommended)",
                        description: "Long-press (1.5 sec) any item, button, or empty area"
                    )
                }
                
                // Passcode unlock
                unlockMethodRow(
                    icon: "key.fill",
                    title: authService.biometricType == .none ? "Your Passcode" : "Passcode",
                    description: unlockDescriptionForCurrentDecoy
                )
            }
            .padding(.horizontal)
            
            // Success message if passcode was set
            if passcodeSet {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Passcode set successfully!")
                        .font(.subheadline)
                }
                .foregroundStyle(.white)
                .padding()
                .background(.green.opacity(0.2))
                .cornerRadius(10)
            }
        }
    }
    
    private func unlockMethodRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var unlockDescriptionForCurrentDecoy: String {
        switch stealthService.decoyScreen {
        case .calculator:
            return "Type your passcode and press ="
        case .notes:
            return "Type your passcode in a new note"
        case .crossStitch:
            return "Type your passcode in the search bar"
        case .weather:
            return "Type your passcode in the search bar"
        case .voiceChanger:
            return "Passcode entry not hidden - use biometric trigger"
        }
    }
    
    private func completeOnboarding() {
        isAuthenticated = true
        hasCompletedOnboarding = true
        // New users land in the app, not the decoy (the service launches locked-by-default).
        stealthService.isStealthActive = false
        dismiss()
    }
}

// MARK: - Email Signup View (Required Step)

struct EmailSignupView: View {
    @Binding var isAuthenticated: Bool
    @Binding var hasCompletedOnboarding: Bool
    @Binding var showingStealthWalkthrough: Bool
    
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
                    // Success - dismiss email signup and show stealth walkthrough
                    await MainActor.run {
                        dismiss()
                        // Small delay to allow sheet to dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingStealthWalkthrough = true
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
