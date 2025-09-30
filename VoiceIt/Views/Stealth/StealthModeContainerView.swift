import SwiftUI

/// Container view that shows decoy screens or actual content based on stealth mode
struct StealthModeContainerView<Content: View>: View {
    @State private var stealthService: StealthModeService
    @State private var showUnlockPrompt = false
    @State private var isUnlocking = false
    @State private var unlockError: String?
    
    let content: Content
    
    init(stealthService: StealthModeService, @ViewBuilder content: () -> Content) {
        _stealthService = State(initialValue: stealthService)
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if stealthService.isStealthActive {
                // Show decoy screen
                decoyScreen
                    .transition(.opacity)
                
                // Unlock gesture area at top
                GeometryReader { geometry in
                    Color.clear
                        .frame(height: 60)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 30)
                                .onEnded { value in
                                    if value.translation.height > 50 {
                                        showUnlockPrompt = true
                                    }
                                }
                        )
                }
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
    
    @ViewBuilder
    private var decoyScreen: some View {
        switch stealthService.decoyScreen {
        case .calculator:
            CalculatorDecoyView()
        case .weather:
            WeatherDecoyView()
        case .notes:
            NotesDecoyView()
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
                try await stealthService.deactivateStealthMode()
                await MainActor.run {
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
