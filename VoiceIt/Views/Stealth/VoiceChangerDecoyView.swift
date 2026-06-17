import SwiftUI

/// Decoy Voice Changer screen
struct VoiceChangerDecoyView: View {
    @State private var service = VoiceChangerService()
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    
    @State private var selectedPreset: VoiceEffectPreset = .normal
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Unlock trigger properties
    @State private var isLongPressing = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                Text("Voice It FX")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 40)
                
                // Visualization Area (Simple dummy visualizer)
                HStack(spacing: 4) {
                    ForEach(0..<15) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(service.isRecording || service.isPlaying ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 40 + CGFloat(index % 5) * 10)
                            .animation(
                                (service.isRecording || service.isPlaying) ? 
                                    .easeInOut(duration: 0.2).repeatForever().delay(Double(index) * 0.05) : .default,
                                value: service.isRecording || service.isPlaying
                            )
                    }
                }
                .frame(height: 100)
                .padding()
                
                // Controls
                VStack(spacing: 40) {
                    
                    // Presets Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(VoiceEffectPreset.allCases, id: \.self) { preset in
                            PresetButton(
                                preset: preset,
                                isSelected: selectedPreset == preset
                            ) {
                                selectedPreset = preset
                                service.applyPreset(preset)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Main Record/Play Button
                    ZStack {
                        if service.isRecording {
                            // Stop Button
                            Button {
                                service.stopRecording()
                            } label: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .frame(width: 40, height: 40)
                                    .padding(20)
                                    .background(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                    )
                            }
                        } else if service.hasRecording {
                            HStack(spacing: 40) {
                                // Delete/Reset
                                Button {
                                    service.stopPlayback()
                                    service.hasRecording = false
                                } label: {
                                    Image(systemName: "trash.fill")
                                        .font(.title2)
                                        .foregroundStyle(.gray)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                
                                // Play/Stop
                                Button {
                                    if service.isPlaying {
                                        service.stopPlayback()
                                    } else {
                                        do {
                                            try service.playRecording()
                                        } catch {
                                            errorMessage = error.localizedDescription
                                            showError = true
                                        }
                                    }
                                } label: {
                                    Image(systemName: service.isPlaying ? "stop.fill" : "play.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white)
                                        .frame(width: 80, height: 80)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                        .shadow(color: .green.opacity(0.4), radius: 10)
                                }
                                
                                // Unlock Trigger (Hidden or specific button)
                                // We'll put the long-press unlock on the Record button (when not recording)
                                // But here we are in playback mode.
                                // Let's add a "Save" button that does nothing but is clickable
                                Button {
                                    // Fake save
                                } label: {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title2)
                                        .foregroundStyle(.gray)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        } else {
                            // Record Button
                            Button {
                                do {
                                    try service.startRecording()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            } label: {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 70, height: 70)
                                    .padding(5)
                                    .background(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                    )
                            }
                            // STEALTH UNLOCK TRIGGER
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 1.5)
                                    .onEnded { _ in
                                        triggerUnlock()
                                    }
                            )
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func triggerUnlock() {
        Task {
            do {
                try await authService.authenticateWithBiometrics(reason: "Unlock Voice It")
                await MainActor.run {
                    stealthService.isStealthActive = false
                }
            } catch {
                // Fail silently or handle error if needed
                print("Unlock failed: \(error)")
            }
        }
    }
}

struct PresetButton: View {
    let preset: VoiceEffectPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.3) : Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: preset.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? color : .gray)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                )
                
                Text(preset.rawValue)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .gray)
            }
        }
    }
    
    var color: Color {
        switch preset {
        case .normal: return .blue
        case .chipmunk: return .orange
        case .monster: return .purple
        case .robot: return .gray
        case .echo: return .teal
        }
    }
}

#Preview {
    VoiceChangerDecoyView()
        .environment(\.authenticationService, AuthenticationService())
        .environment(\.stealthModeService, StealthModeService())
}
