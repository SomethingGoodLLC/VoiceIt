import SwiftUI

/// Settings view for configuring stealth mode options
struct StealthModeSettingsView: View {
    @State private var stealthService: StealthModeService
    @State private var selectedDecoy: DecoyScreenType
    @State private var autoHideEnabled = false
    @State private var autoHideMinutes: Double = 5
    @State private var appIconService = AppIconService.shared
    @State private var isChangingIcon = false
    @State private var showingIconChangeAlert = false
    @State private var pendingDecoy: DecoyScreenType?
    @State private var iconChangeError: String?
    @State private var showingIconChangeError = false
    
    init(stealthService: StealthModeService) {
        _stealthService = State(initialValue: stealthService)
        _selectedDecoy = State(initialValue: stealthService.decoyScreen)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Decoy Screen", selection: $selectedDecoy) {
                    ForEach(DecoyScreenType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .onChange(of: selectedDecoy) { oldType, newType in
                    // Only trigger alert if the selection actually changed from the current service value
                    if newType != stealthService.decoyScreen {
                        pendingDecoy = newType
                        showingIconChangeAlert = true
                        
                        // Revert the picker selection visually until confirmed
                        selectedDecoy = stealthService.decoyScreen
                    }
                }
            } header: {
                Text("Decoy Screen Type")
            } footer: {
                Text("Choose which app to display when stealth mode is active. The app icon will automatically change to match.")
            }
            
            Section {
                Toggle("Auto-hide after inactivity", isOn: $autoHideEnabled)
                
                if autoHideEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auto-hide after: \(Int(autoHideMinutes)) minutes")
                            .font(.subheadline)
                        
                        Slider(value: $autoHideMinutes, in: 1...30, step: 1)
                    }
                }
            } header: {
                Text("Auto-Hide")
            } footer: {
                Text("Automatically activate stealth mode after the specified period of inactivity")
            }
            .onChange(of: autoHideEnabled) { _, isEnabled in
                updateAutoHide()
            }
            .onChange(of: autoHideMinutes) { _, _ in
                updateAutoHide()
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Passcode Unlock")
                            .font(.headline)
                        Text(passcodeUnlockDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biometric Unlock")
                            .font(.headline)
                        Text(biometricUnlockDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } header: {
                Text("Unlock Methods")
            } footer: {
                Text("Use your passcode or Face ID/Touch ID to unlock the app from the decoy screen.")
            }
            
            Section {
                Button {
                    testStealthMode()
                } label: {
                    Label("Test Stealth Mode", systemImage: "play.circle.fill")
                }
            } header: {
                Text("Testing")
            } footer: {
                Text("Test the stealth mode to see how it works. You'll need to unlock to return.")
            }
        }
        .navigationTitle("Stealth Mode")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Change App Icon?", isPresented: $showingIconChangeAlert, presenting: pendingDecoy) { decoy in
            Button("Change Icon & Decoy") {
                selectedDecoy = decoy
                stealthService.setDecoyScreen(decoy)
                changeIconToMatch(decoy)
            }
            Button("Cancel", role: .cancel) {
                pendingDecoy = nil
            }
        } message: { decoy in
            Text("Choosing '\(decoy.displayName)' will also change the app icon on your home screen to match this disguise.")
        }
        .alert("Icon Change Failed", isPresented: $showingIconChangeError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(iconChangeError ?? "Unknown error occurred")
        }
    }
    
    private func updateAutoHide() {
        let delay = autoHideEnabled ? autoHideMinutes * 60 : 0
        stealthService.setAutoHideDelay(delay)
    }
    
    private func testStealthMode() {
        stealthService.activateStealthMode(decoy: selectedDecoy)
    }
    
    private var passcodeUnlockDescription: String {
        switch selectedDecoy {
        case .calculator:
            return "Type your passcode on the calculator and press ="
        case .notes:
            return "Type your passcode in a new note and press return"
        case .crossStitch:
            return "Type your passcode in the search bar"
        case .weather:
            return "Type your passcode in the search bar"
        case .voiceChanger:
            return "Passcode entry not hidden - use biometric trigger"
        }
    }
    
    private var biometricUnlockDescription: String {
        switch selectedDecoy {
        case .calculator:
            return "Long-press the = button to unlock with Face ID"
        case .notes:
            return "Long-press the + button to unlock with Face ID"
        case .crossStitch:
            return "Long-press the + button to unlock with Face ID"
        case .weather:
            return "Long-press the refresh button to unlock with Face ID"
        case .voiceChanger:
            return "Long-press the record button to unlock with Face ID"
        }
    }
    
    private func changeIconToMatch(_ decoy: DecoyScreenType) {
        Task { @MainActor in
            isChangingIcon = true
            
            // Map decoy type to app icon
            let appIcon: AppIcon
            switch decoy {
            case .calculator:
                appIcon = .calculator
            case .notes:
                appIcon = .notes
            case .crossStitch:
                appIcon = .crossStitch
            case .weather:
                appIcon = .weather
            case .voiceChanger:
                appIcon = .voiceChanger
            }
            
            print("🔄 StealthModeSettingsView: Attempting to change icon to \(appIcon.rawValue)")
            print("🔄 StealthModeSettingsView: supportsAlternateIcons = \(appIconService.supportsAlternateIcons)")
            print("🔄 StealthModeSettingsView: Current icon before change = \(appIconService.currentIcon.rawValue)")
            
            do {
                try await appIconService.changeIcon(to: appIcon)
                print("✅ StealthModeSettingsView: Icon change completed successfully")
                print("✅ StealthModeSettingsView: Current icon after change = \(appIconService.currentIcon.rawValue)")
            } catch {
                print("❌ StealthModeSettingsView: Failed to change app icon: \(error)")
                iconChangeError = "Failed to change icon: \(error.localizedDescription)"
                showingIconChangeError = true
            }
            
            isChangingIcon = false
        }
    }
}

#Preview {
    NavigationStack {
        StealthModeSettingsView(stealthService: StealthModeService())
    }
}
