import SwiftUI

/// Comprehensive settings screen with security and privacy options
struct SettingsView: View {
    // MARK: - Environment
    
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    @Environment(\.apiService) private var apiService
    @State private var appIconService = AppIconService.shared
    @State private var notificationService = NotificationService()
    @State private var hapticService = HapticService.shared
    
    // MARK: - State
    
    @State private var showingPasscodeSetup = false
    @State private var showingAppIconPicker = false
    @State private var showingAbout = false
    @State private var showingResetConfirmation = false
    @State private var developerModeCounter = 0
    @State private var showDeveloperMode = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                securitySection
                appearanceSection
                stealthModeSection
                transcriptionSection
                privacySection
                notificationSection
                exportSection
                aboutSection
                
                if showDeveloperMode {
                    developerSection
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPasscodeSetup) {
                PasscodeSetupView()
            }
            .sheet(isPresented: $showingAppIconPicker) {
                AppIconPickerView(service: appIconService)
            }
            .alert("Reset All Data", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    // TODO: Implement data reset
                }
            } message: {
                Text("This will permanently delete all evidence and settings. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        Section {
            // Show biometric toggle only if device supports biometrics
            if authService.biometricType != .none {
                Toggle(isOn: Binding(
                    get: { authService.isBiometricEnabled },
                    set: { newValue in
                        if newValue {
                            // Enabling biometrics - authenticate first
                            Task {
                                await enableBiometrics()
                            }
                        } else {
                            // Disabling biometrics
                            authService.isBiometricEnabled = false
                        }
                    }
                )) {
                    Label(authService.biometricType.displayName, systemImage: authService.biometricType.icon)
                }
            } else {
                // Show informational row when biometrics not available
                HStack {
                    Label("Biometrics", systemImage: "lock.fill")
                    Spacer()
                    Text("Not Available")
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                showingPasscodeSetup = true
            } label: {
                Label("Change Passcode", systemImage: "key.fill")
            }
            
            Picker("Auto-Lock", selection: Binding(
                get: { authService.autoLockTimeout },
                set: { authService.autoLockTimeout = $0 }
            )) {
                Text("1 minute").tag(TimeInterval(60))
                Text("5 minutes").tag(TimeInterval(300))
                Text("15 minutes").tag(TimeInterval(900))
                Text("30 minutes").tag(TimeInterval(1800))
                Text("Never").tag(TimeInterval.infinity)
            }
            
        } header: {
            Text("Security")
        } footer: {
            if authService.biometricType == .none {
                Text("Biometric authentication is not available on this device. Use your passcode to unlock the app.")
            } else {
                Text("Protect your evidence with biometric authentication and automatic locking.")
            }
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            Button {
                showingAppIconPicker = true
            } label: {
                HStack {
                    Label("App Icon", systemImage: "app.badge")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: appIconService.currentIcon.previewIcon)
                            .foregroundStyle(.secondary)
                        Text(appIconService.currentIcon.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .foregroundStyle(.primary)
        } header: {
            Text("Appearance")
        } footer: {
            Text("Choose an app icon to disguise the app.")
        }
    }

    // MARK: - Stealth Mode Section
    
    private var stealthModeSection: some View {
        Section {
            NavigationLink {
                StealthModeSettingsView(stealthService: stealthService)
            } label: {
                Label("Stealth Mode Settings", systemImage: "eye.slash.fill")
            }
            
            HStack {
                Label("To Hide App", systemImage: "rectangle.portrait.and.arrow.right")
                Spacer()
                Text("Go to Home Screen")
                    .foregroundStyle(.secondary)
            }
            
        } header: {
            Text("Stealth & Disguise")
        } footer: {
            Text("Change app appearance and enable quick hide features for safety.")
        }
    }
    
    // MARK: - Transcription Section
    
    private var transcriptionSection: some View {
        Section {
            NavigationLink {
                TranscriptionSettingsView()
            } label: {
                Label("Transcription Settings", systemImage: "waveform")
            }
            
        } header: {
            Text("Voice Notes")
        } footer: {
            Text("Configure offline transcription with Whisper for 100% private voice recognition.")
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { UserDefaults.standard.bool(forKey: "disableScreenshots") },
                set: { UserDefaults.standard.set($0, forKey: "disableScreenshots") }
            )) {
                Label("Block Screenshots", systemImage: "camera.fill")
            }
            
            Toggle(isOn: Binding(
                get: { UserDefaults.standard.bool(forKey: "trackLocation") },
                set: { UserDefaults.standard.set($0, forKey: "trackLocation") }
            )) {
                Label("Location Tracking", systemImage: "location.fill")
            }
            
            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                Label("Clear All Data", systemImage: "trash.fill")
            }
            
        } header: {
            Text("Privacy")
        } footer: {
            Text("All data stays on this device. No analytics or tracking. Location tracking helps document evidence but can be disabled.")
        }
    }
    
    // MARK: - Notification Section
    
    private var notificationSection: some View {
        Section {
            Picker("Notification Style", selection: Binding(
                get: { notificationService.contentStyle },
                set: { notificationService.contentStyle = $0 }
            )) {
                ForEach(NotificationContentStyle.allCases, id: \.self) { style in
                    Text(style.displayName).tag(style)
                }
            }
            
            if notificationService.contentStyle != .generic {
                Text("Example: \(notificationService.contentStyle.example)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
        } header: {
            Text("Notifications")
        } footer: {
            Text("Customize notification text for privacy. Generic notifications don't reveal what the app is for.")
        }
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        Section {
            Picker("Default Export Format", selection: Binding(
                get: { UserDefaults.standard.string(forKey: "defaultExportFormat") ?? "PDF" },
                set: { UserDefaults.standard.set($0, forKey: "defaultExportFormat") }
            )) {
                Text("PDF").tag("PDF")
                Text("Word (RTF)").tag("RTF")
                Text("JSON").tag("JSON")
            }
            
            Toggle(isOn: Binding(
                get: { UserDefaults.standard.bool(forKey: "requireExportPassword") },
                set: { UserDefaults.standard.set($0, forKey: "requireExportPassword") }
            )) {
                Label("Require Password Protection", systemImage: "lock.fill")
            }
            
        } header: {
            Text("Export")
        } footer: {
            Text("Configure default settings for exporting evidence.")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            
            NavigationLink {
                TermsOfServiceView()
            } label: {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }
            
            NavigationLink {
                SupportContactView()
            } label: {
                Label("Support & Safety Resources", systemImage: "heart.fill")
            }
            
            Button {
                developerModeCounter += 1
                if developerModeCounter >= 5 {
                    showDeveloperMode = true
                    HapticService.shared.success()
                }
            } label: {
                HStack {
                    Text("App Version")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
            
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Developer Section (Hidden)
    
    private var developerSection: some View {
        Section {
            NavigationLink {
                DebugRoadmapEventsView()
            } label: {
                Label("Roadmap Analytics Events", systemImage: "chart.bar.doc.horizontal")
            }
            
            Button(role: .destructive) {
                showDeveloperMode = false
                developerModeCounter = 0
            } label: {
                Label("Hide Developer Options", systemImage: "eye.slash")
            }
        } header: {
            HStack {
                Text("Developer")
                Image(systemName: "hammer.fill")
                    .font(.caption)
            }
        } footer: {
            Text("These options are for development and debugging purposes.")
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    private func enableBiometrics() async {
        do {
            try await authService.authenticate(reason: "Enable \(authService.biometricType.displayName) for Voice It")
            authService.isBiometricEnabled = true
            HapticService.shared.success()
        } catch {
            // Authentication failed, toggle stays off
            authService.isBiometricEnabled = false
            HapticService.shared.error()
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.authenticationService, AuthenticationService())
        .environment(\.stealthModeService, StealthModeService())
}
