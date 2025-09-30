import SwiftUI
import SwiftData
import CoreHaptics

/// Persistent floating panic button with hold-to-activate functionality
struct PanicButtonView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stealthService: StealthModeService
    @State private var emergencyService: EmergencyService
    @State private var locationService: LocationService
    @State private var audioRecordingService: AudioRecordingService
    
    // Button state
    @State private var isMinimized = false
    @State private var isHolding = false
    @State private var holdProgress: Double = 0
    @State private var position: CGPoint = .zero
    @State private var showCancelSheet = false
    @State private var countdownSeconds = 3
    @State private var isActivated = false
    
    // Haptics
    @State private var hapticEngine: CHHapticEngine?
    
    // Timer
    @State private var holdTimer: Timer?
    @State private var countdownTimer: Timer?
    
    private let holdDuration: TimeInterval = 3.0
    private let buttonSize: CGFloat = 60
    private let minimizedSize: CGFloat = 44
    
    init(
        stealthService: StealthModeService,
        emergencyService: EmergencyService,
        locationService: LocationService,
        audioRecordingService: AudioRecordingService
    ) {
        _stealthService = State(initialValue: stealthService)
        _emergencyService = State(initialValue: emergencyService)
        _locationService = State(initialValue: locationService)
        _audioRecordingService = State(initialValue: audioRecordingService)
    }
    
    var body: some View {
        ZStack {
            if !isMinimized {
                // Full button
                fullButton
            } else {
                // Minimized button
                minimizedButton
            }
        }
        .onAppear {
            setupInitialPosition()
            setupHaptics()
        }
        .sheet(isPresented: $showCancelSheet) {
            cancelSheet
        }
    }
    
    private var fullButton: some View {
        VStack(spacing: 8) {
            ZStack {
                // Progress ring
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 6)
                    .frame(width: buttonSize, height: buttonSize)
                
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(Color.red, lineWidth: 6)
                    .frame(width: buttonSize, height: buttonSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: holdProgress)
                
                // Button content
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: buttonSize - 12, height: buttonSize - 12)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .scaleEffect(isHolding ? 0.9 : 1.0)
                .animation(.spring(response: 0.3), value: isHolding)
            }
            
            // Hold instruction
            if !isHolding {
                Text("Hold for SOS")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Text("\(Int((1 - holdProgress) * holdDuration))s")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundColor(.red)
            }
            
            // Minimize button
            Button {
                withAnimation {
                    isMinimized = true
                }
            } label: {
                Image(systemName: "chevron.compact.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        .position(position)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // If drag distance is significant, treat as drag to move button
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    
                    if dragDistance > 10 {
                        // User is dragging - move the button
                        position = value.location
                        // Cancel hold if we were holding
                        if isHolding {
                            print("❌ Hold cancelled - dragging")
                            stopHolding()
                        }
                    } else {
                        // User is pressing in place - start hold timer if not already holding
                        if !isHolding {
                            print("👇 Press detected - starting hold")
                            startHolding()
                        }
                    }
                }
                .onEnded { value in
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    
                    if dragDistance <= 10 {
                        // Was a hold, not a drag
                        // Check if still holding (panic may have already activated)
                        if isHolding {
                            print("❌ Hold released early at \(Int(holdProgress * 100))%")
                            stopHolding()
                        }
                    } else {
                        // Was a drag
                        if isHolding {
                            print("❌ Hold cancelled - was dragging")
                            stopHolding()
                        }
                    }
                }
        )
    }
    
    private var minimizedButton: some View {
        Button {
            withAnimation {
                isMinimized = false
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: minimizedSize, height: minimizedSize)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
        .position(CGPoint(x: UIScreen.main.bounds.width - 30, y: 100))
    }
    
    private var cancelSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Emergency Activated")
                    .font(.title2.bold())
                
                Text("Emergency services will be contacted in \(countdownSeconds) seconds")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Text("✓ Location captured")
                    Text("✓ Recording started")
                    Text("✓ Contacts will be notified")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    cancelEmergency()
                } label: {
                    Text("I'm Safe - Cancel")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("SOS Activated")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Actions
    
    private func setupInitialPosition() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        position = CGPoint(x: screenWidth - 60, y: screenHeight - 150)
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to setup haptics: \(error)")
        }
    }
    
    private func startHolding() {
        isHolding = true
        holdProgress = 0
        
        print("⏱️ Starting hold timer...")
        
        // Start progress timer
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                self.holdProgress += 0.05 / self.holdDuration
                
                // Haptic feedback every 0.5 seconds
                if self.holdProgress.truncatingRemainder(dividingBy: 0.17) < 0.05 {
                    self.playHaptic()
                }
                
                // Auto-activate when progress reaches 100%
                if self.holdProgress >= 1.0 {
                    print("✅ Hold timer completed - auto-activating!")
                    self.holdTimer?.invalidate()
                    self.holdTimer = nil
                    self.activatePanic()
                }
            }
        }
    }
    
    private func stopHolding() {
        isHolding = false
        holdProgress = 0
        holdTimer?.invalidate()
        holdTimer = nil
    }
    
    private func activatePanic() {
        print("⚠️ Panic activated!")
        isActivated = true
        stopHolding()
        
        // Strong haptic feedback
        playStrongHaptic()
        
        // Show cancel sheet
        showCancelSheet = true
        countdownSeconds = 3
        
        print("📱 Starting emergency sequence...")
        // Start countdown
        Task {
            await startEmergencySequence()
        }
    }
    
    private func startEmergencySequence() async {
        print("🔄 Emergency sequence started")
        
        // Capture location
        locationService.requestLocation()
        print("📍 Location requested")
        
        // Start silent recording
        do {
            _ = try await audioRecordingService.startRecording()
            print("🎤 Recording started")
        } catch {
            print("⚠️ Failed to start recording: \(error)")
        }
        
        print("⏰ Starting countdown timer...")
        
        // Countdown timer - run on main thread
        await MainActor.run {
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak countdownTimer] _ in
                print("⏱️ Countdown tick: \(self.countdownSeconds)")
                
                self.countdownSeconds -= 1
                self.playHaptic()
                
                if self.countdownSeconds <= 0 {
                    print("🎯 Countdown reached 0! Executing emergency...")
                    countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    
                    Task { @MainActor in
                        await self.executeEmergency()
                    }
                }
            }
            print("✅ Timer scheduled")
        }
    }
    
    @MainActor
    private func executeEmergency() async {
        print("🚨 Executing emergency!")
        
        // Get location snapshot
        let location = await locationService.createSnapshot()
        print("📍 Location captured: \(location?.coordinatesString ?? "none")")
        
        // Get emergency contacts
        let descriptor = FetchDescriptor<EmergencyContact>()
        let contacts = (try? modelContext.fetch(descriptor)) ?? []
        
        print("👥 Found \(contacts.count) emergency contacts")
        
        // Activate emergency service
        await emergencyService.activatePanicButton(
            emergencyContacts: contacts,
            location: location
        )
        
        print("✅ Emergency service activated")
        
        // Close sheet and reset
        showCancelSheet = false
        isActivated = false
    }
    
    private func cancelEmergency() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // Stop recording
        Task {
            _ = await audioRecordingService.stopRecording()
        }
        
        showCancelSheet = false
        isActivated = false
        stopHolding()
    }
    
    private func playHaptic() {
        guard let engine = hapticEngine else { return }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic error: \(error)")
        }
    }
    
    private func playStrongHaptic() {
        guard let engine = hapticEngine else { return }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic error: \(error)")
        }
    }
}
