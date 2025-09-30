import SwiftUI

/// Settings view for configuring stealth mode options
struct StealthModeSettingsView: View {
    @State private var stealthService: StealthModeService
    @State private var selectedDecoy: DecoyScreenType
    @State private var autoHideEnabled = false
    @State private var autoHideMinutes: Double = 5
    
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
                .onChange(of: selectedDecoy) { _, newValue in
                    stealthService.setDecoyScreen(newValue)
                }
            } header: {
                Text("Decoy Screen Type")
            } footer: {
                Text("Choose which app to display when stealth mode is active")
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
                        Text("Shake to Hide")
                            .font(.headline)
                        Text("Shake device to quickly activate stealth mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swipe Down to Unlock")
                            .font(.headline)
                        Text("Swipe down from top of decoy screen to unlock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } header: {
                Text("Quick Actions")
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
    }
    
    private func updateAutoHide() {
        let delay = autoHideEnabled ? autoHideMinutes * 60 : 0
        stealthService.setAutoHideDelay(delay)
    }
    
    private func testStealthMode() {
        stealthService.activateStealthMode(decoy: selectedDecoy)
    }
}

#Preview {
    NavigationStack {
        StealthModeSettingsView(stealthService: StealthModeService())
    }
}
