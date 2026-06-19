import SwiftUI

/// Container view that shows decoy screens or actual content based on stealth mode
struct StealthModeContainerView<Content: View>: View {
    let stealthService: StealthModeService
    @State private var showUnlockPrompt = false
    @State private var isUnlocking = false
    @State private var unlockError: String?
    
    let content: Content
    
    init(stealthService: StealthModeService, onUnlock: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.stealthService = stealthService
        self.onUnlock = onUnlock
        self.content = content()
    }
    
    private let onUnlock: (() -> Void)?
    
    var body: some View {
        ZStack {
            if stealthService.isStealthActive {
                // Show decoy screen
                DecoyScreenView(decoyType: stealthService.decoyScreen)
                    .transition(.opacity)
                    .onChange(of: stealthService.isStealthActive) { oldValue, newValue in
                        if !newValue {
                            // If stealth mode became inactive (unlocked), notify parent
                            onUnlock?()
                        }
                    }
                
                // Remove swipe down gesture - unlocking is now done via the decoy apps
            } else {
                // Show actual content
                content
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: stealthService.isStealthActive)
        .sheet(isPresented: $showUnlockPrompt) {
            unlockPromptView
        }
    }
    
    private var unlockPromptView: some View {
        VStack(spacing: 24) {
            if isUnlocking {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Authenticating...")
                    .font(.headline)
            } else {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.voiceitPurple)
                    .padding()
                
                Text("Unlock Voice It")
                    .font(.title2.bold())
                
                Text("Use Face ID, Touch ID, or your passcode to unlock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let error = unlockError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button {
                    attemptUnlock()
                } label: {
                    Label("Unlock", systemImage: "lock.open.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.voiceitPurple)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top)
            }
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func attemptUnlock() {
        isUnlocking = true
        unlockError = nil
        
        Task {
            do {
                // First, authenticate the user
                try await stealthService.authenticate()
                
                await MainActor.run {
                    // Then notify parent to set authentication state BEFORE deactivating stealth
                    onUnlock?()
                    
                    // Finally, deactivate stealth mode (without re-authenticating)
                    stealthService.completeUnlock()
                    
                    isUnlocking = false
                    showUnlockPrompt = false
                }
            } catch {
                await MainActor.run {
                    isUnlocking = false
                    unlockError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    StealthModeContainerView(stealthService: StealthModeService()) {
        Text("Main Content")
    }
}
