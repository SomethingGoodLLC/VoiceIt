import SwiftUI

/// View for managing backend account (login/signup/logout)
struct AccountManagementView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewMode: ViewMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingForgotPassword = false
    
    private let apiService = APIService.shared
    
    enum ViewMode {
        case login
        case signup
        case loggedIn
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voiceitGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: apiService.isAuthenticated ? "checkmark.shield.fill" : "cloud.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.white)
                            
                            Text(apiService.isAuthenticated ? "Account Connected" : "Cloud Sync")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text(apiService.isAuthenticated ? "Your evidence can now sync to the cloud" : "Optional cloud backup and sync")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 30)
                        
                        // Content based on state
                        if apiService.isAuthenticated {
                            loggedInView
                        } else {
                            if viewMode == .login {
                                loginView
                            } else {
                                signupView
                            }
                        }
                        
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
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    // MARK: - Login View
    
    private var loginView: some View {
        VStack(spacing: 20) {
            // Email field
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle()
            
            // Password field
            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle()
            
            // Login button
            Button {
                Task {
                    await handleLogin()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Log In")
                        .font(.headline)
                }
            }
            .buttonStyle(.primary)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            
            // Forgot password
            Button {
                showingForgotPassword = true
            } label: {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            // Divider
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical)
            
            // Switch to signup
            Button {
                withAnimation {
                    viewMode = .signup
                    errorMessage = ""
                }
            } label: {
                Text("Create New Account")
                    .font(.headline)
            }
            .buttonStyle(.secondary)
            
            // Skip button
            Button {
                dismiss()
            } label: {
                Text("Skip for Now")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Signup View
    
    private var signupView: some View {
        VStack(spacing: 20) {
            // Name field (optional)
            TextField("Name (optional)", text: $name)
                .textContentType(.name)
                .textFieldStyle()
            
            // Email field
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle()
            
            // Password field
            SecureField("Password (min 6 characters)", text: $password)
                .textContentType(.newPassword)
                .textFieldStyle()
            
            // Confirm password field
            SecureField("Confirm Password", text: $confirmPassword)
                .textContentType(.newPassword)
                .textFieldStyle()
            
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
            
            // Signup button
            Button {
                Task {
                    await handleSignup()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
                        .font(.headline)
                }
            }
            .buttonStyle(.primary)
            .disabled(isLoading || email.isEmpty || password.isEmpty || password != confirmPassword || password.count < 6)
            
            // Privacy note
            Text("Your data remains encrypted. Cloud sync is optional.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Divider
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical)
            
            // Switch to login
            Button {
                withAnimation {
                    viewMode = .login
                    errorMessage = ""
                }
            } label: {
                Text("Already Have an Account?")
                    .font(.headline)
            }
            .buttonStyle(.secondary)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Logged In View
    
    private var loggedInView: some View {
        VStack(spacing: 24) {
            // User info
            VStack(spacing: 12) {
                if let user = apiService.currentUser {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let name = user.name, !name.isEmpty {
                                Text(name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.white.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            
            // Sync status - Coming Soon
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "icloud")
                        .foregroundStyle(.white.opacity(0.6))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cloud Sync")
                            .foregroundStyle(.white)
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.3))
                            .cornerRadius(4)
                    }
                    Spacer()
                    Toggle("", isOn: .constant(false))
                        .labelsHidden()
                        .disabled(true)
                }
                .padding()
                .background(.white.opacity(0.2))
                .cornerRadius(12)
                
                Text("Cloud sync will be available once backend endpoints are ready")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Logout button
            Button(role: .destructive) {
                handleLogout()
            } label: {
                Label("Log Out", systemImage: "arrow.right.square")
                    .font(.headline)
            }
            .buttonStyle(.secondary)
            .padding(.top, 20)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func handleLogin() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let response = try await apiService.login(email: email, password: password)
            
            if response.success {
                // Success - dismiss view
                await MainActor.run {
                    dismiss()
                }
            } else {
                errorMessage = response.message ?? "Login failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func handleSignup() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let response = try await apiService.signUp(
                email: email,
                password: password,
                name: name.isEmpty ? nil : name
            )
            
            if response.success {
                // Success - dismiss view
                await MainActor.run {
                    dismiss()
                }
            } else {
                errorMessage = response.message ?? "Signup failed"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func handleLogout() {
        apiService.logout()
        TimelineSyncService.shared.isSyncEnabled = false
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
        viewMode = .login
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var isSuccess = false
    
    private let apiService = APIService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.voiceitGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                        
                        Text("Forgot Password?")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Enter your email to receive a password reset link")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Email field
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle()
                        .padding(.horizontal)
                    
                    // Submit button
                    Button {
                        Task {
                            await handleForgotPassword()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Reset Link")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(isLoading || email.isEmpty)
                    .padding(.horizontal)
                    
                    // Message
                    if !message.isEmpty {
                        Text(message)
                            .foregroundStyle(.white)
                            .font(.caption)
                            .padding()
                            .background(isSuccess ? .green.opacity(0.3) : .red.opacity(0.3))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func handleForgotPassword() async {
        isLoading = true
        message = ""
        
        do {
            let response = try await apiService.forgotPassword(email: email)
            isSuccess = response.success
            message = response.message ?? "If an account exists, you'll receive a reset link."
            
            if isSuccess {
                // Wait 2 seconds then dismiss
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    dismiss()
                }
            }
        } catch {
            isSuccess = false
            message = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Custom View Modifiers

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.white.opacity(configuration.isPressed ? 0.15 : 0.25))
            .cornerRadius(12)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.white.opacity(configuration.isPressed ? 0.05 : 0.1))
            .cornerRadius(12)
    }
}

private struct TextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white.opacity(0.2))
            .foregroundStyle(.white)
            .cornerRadius(12)
            .tint(.white)
    }
}

extension View {
    func textFieldStyle() -> some View {
        modifier(TextFieldModifier())
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

#Preview {
    AccountManagementView()
}

