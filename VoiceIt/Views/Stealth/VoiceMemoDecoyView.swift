import SwiftUI

/// Decoy view that looks like a Voice Memo app
/// Unlock Trigger: Long press the record button
struct VoiceMemoDecoyView: View {
    @Environment(\.stealthModeService) private var stealthService
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var waveformHeights: [CGFloat] = Array(repeating: 30, count: 40)
    
    // Unlock gesture state
    @State private var isLongPressing = false
    @State private var longPressStartTime: Date?
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {}) {
                        Text("Edit")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding()
                
                // Main Content
                Spacer()
                
                Text(isRecording ? "New Recording" : "All Recordings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)
                
                Text(timeString(from: recordingDuration))
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // Fake Waveform
                HStack(spacing: 3) {
                    ForEach(0..<40, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red.opacity(isRecording ? 1.0 : 0.3))
                            .frame(width: 3, height: waveformHeights[index])
                            .animation(.spring(response: 0.2), value: waveformHeights[index])
                    }
                }
                .frame(height: 100)
                .padding(.vertical, 40)
                .opacity(isRecording ? 1.0 : 0.0)
                
                Spacer()
                
                // Controls
                ZStack {
                    // Bottom Card Background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.systemGray6))
                        .ignoresSafeArea()
                        .frame(height: 250)
                        .offset(y: 50)
                    
                    VStack {
                        // Record Button
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: isRecording ? 30 : 60, height: isRecording ? 30 : 60)
                                .cornerRadius(isRecording ? 4 : 30)
                                .scaleEffect(isLongPressing ? 1.1 : 1.0)
                                .animation(.spring(), value: isRecording)
                        }
                        .padding(.bottom, 30)
                        .onLongPressGesture(minimumDuration: 0.5) {
                            // Trigger unlock
                            Task {
                                try? await stealthService.deactivateStealthMode()
                            }
                        } onPressingChanged: { pressing in
                            isLongPressing = pressing
                            if pressing && !isRecording {
                                // Start fake recording immediately on press for realism
                                startRecording()
                            } else if !pressing && isRecording && !stealthService.isStealthActive {
                                // Stop fake recording if released without triggering unlock (if quick tap)
                                // Actually, keep recording to be less suspicious if they lift finger
                            }
                        }
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded {
                                    toggleRecording()
                                }
                        )
                    }
                }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        recordingDuration = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            MainActor.assumeIsolated {
                recordingDuration += 0.1
                updateWaveform()
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        waveformHeights = Array(repeating: 30, count: 40)
    }
    
    private func updateWaveform() {
        for i in 0..<waveformHeights.count {
            waveformHeights[i] = CGFloat.random(in: 10...80)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

#Preview {
    VoiceMemoDecoyView()
        .environment(\.stealthModeService, StealthModeService())
}
