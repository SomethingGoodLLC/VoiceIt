import Foundation
import SwiftUI
import Observation
import LocalAuthentication

/// Service for managing stealth mode with decoy screens
@Observable
final class StealthModeService: @unchecked Sendable {
    // MARK: - Properties
    
    /// Whether stealth mode is currently active (persisted to UserDefaults)
    var isStealthActive: Bool = false {
        didSet {
            UserDefaults.standard.set(isStealthActive, forKey: "isStealthModeActive")
        }
    }
    
    /// Selected decoy screen type (persisted to UserDefaults)
    var decoyScreen: DecoyScreenType {
        didSet {
            UserDefaults.standard.set(decoyScreen.rawValue, forKey: "selectedDecoyScreen")
        }
    }
    
    /// Auto-hide after inactivity (in seconds, 0 = disabled)
    var autoHideDelay: TimeInterval = 0
    
    /// Last user interaction timestamp
    private var lastInteraction = Date()
    
    /// Transient privacy overlay shown during brief inactive states (not persisted).
    var isPrivacyShieldVisible: Bool = false
    
    /// Whether didEnterBackground fired during the current lifecycle transition
    private var didReachBackground = false
    
    /// Auto-hide timer
    private var autoHideTimer: Timer?
    
    /// Whether to hide app icon (requires app restart)
    var hideAppIcon = false
    
    /// Authentication context
    private let authContext = LAContext()
    
    // MARK: - Initialization
    
    init() {
        // Load saved decoy screen preference
        if let savedDecoy = UserDefaults.standard.string(forKey: "selectedDecoyScreen"),
           let decoyType = DecoyScreenType(rawValue: savedDecoy) {
            self.decoyScreen = decoyType
        } else {
            self.decoyScreen = .crossStitch
        }
        
        // Privacy-first: always launch into the disguised decoy lock screen.
        // The decoy is the only lock screen; unlocking requires biometric/passcode.
        // The onboarding flow takes precedence on first launch and clears this on completion.
        self.isStealthActive = true
        UserDefaults.standard.set(true, forKey: "isStealthModeActive")
        
        setupNotifications()
        startAutoHideTimer()
    }
    
    deinit {
        stopAutoHideTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        // Transient inactive (Control Center, app switcher snapshot) — privacy shield only
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillResignActive()
        }
        
        // True background — commit stealth lock
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidBecomeActive()
        }
        
        // Listen for app about to terminate (force quit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillTerminate()
        }
        
        // Listen for user interactions to reset auto-hide timer
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recordUserInteraction()
        }
    }
    
    // MARK: - Stealth Mode Control
    
    /// Activate stealth mode.
    /// Passing `nil` preserves the user's currently selected decoy. Lifecycle and
    /// auto-hide activations must use `nil` so backgrounding never resets the decoy.
    @MainActor
    func activateStealthMode(decoy: DecoyScreenType? = nil) {
        if let decoy {
            decoyScreen = decoy
        }
        isPrivacyShieldVisible = false
        isStealthActive = true
        recordUserInteraction()
    }
    
    /// Deactivate stealth mode with authentication
    @MainActor
    func deactivateStealthMode() async throws {
        // Require biometric or passcode authentication
        try await authenticate()
        completeUnlock()
    }
    
    /// Quick hide (used for shake gesture or emergency)
    @MainActor
    func quickHide() {
        activateStealthMode(decoy: decoyScreen)
    }
    
    /// Call after successful auth from a decoy screen to return to the main app.
    @MainActor
    func completeUnlock() {
        clearBackgroundTracking()
        isStealthActive = false
        UserDefaults.standard.set(false, forKey: "isStealthModeActive")
        recordUserInteraction()
    }
    
    // MARK: - Authentication
    
    /// Authenticate user with biometrics or passcode
    func authenticate() async throws {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw StealthModeError.authenticationUnavailable
        }
        
        // Perform authentication
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Voice It"
            ) { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: StealthModeError.authenticationFailed)
                }
            }
        }
    }
    
    // MARK: - Auto-Hide Timer
    
    private func startAutoHideTimer() {
        stopAutoHideTimer()
        
        guard autoHideDelay > 0 else { return }
        
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAutoHide()
        }
    }
    
    private func stopAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
    
    private func checkAutoHide() {
        guard autoHideDelay > 0 else { return }
        
        let elapsed = Date().timeIntervalSince(lastInteraction)
        if elapsed >= autoHideDelay && !isStealthActive {
            Task { @MainActor in
                activateStealthMode()
            }
        }
    }
    
    /// Record user interaction to reset auto-hide timer
    func recordUserInteraction() {
        lastInteraction = Date()
    }
    
    // MARK: - App Lifecycle Handling
    
    /// Show transient privacy overlay on inactive; do not commit stealth lock.
    func handleAppWillResignActive() {
        MainActor.assumeIsolated {
            guard !isStealthActive else { return }
            isPrivacyShieldVisible = true
        }
    }
    
    /// Commit stealth lock when the app truly enters background.
    func handleAppDidEnterBackground() {
        MainActor.assumeIsolated {
            didReachBackground = true
            isPrivacyShieldVisible = false
            activateStealthMode()
        }
    }
    
    func handleAppDidBecomeActive() {
        MainActor.assumeIsolated {
            if !didReachBackground {
                // Transient inactive only — clear overlay without locking.
                isPrivacyShieldVisible = false
            }
            didReachBackground = false
            recordUserInteraction()
        }
    }
    
    private func handleAppWillTerminate() {
        // Ensure stealth mode is active when app is force quit
        // This ensures the decoy screen is shown on next launch
        MainActor.assumeIsolated {
            isStealthActive = true
            UserDefaults.standard.set(true, forKey: "isStealthModeActive")
        }
    }
    
    /// Clear background tracking and privacy shield (used when unlocking)
    @MainActor
    func clearBackgroundTracking() {
        didReachBackground = false
        isPrivacyShieldVisible = false
    }
    
    /// Dismiss the transient privacy overlay without changing stealth lock state.
    @MainActor
    func dismissPrivacyShield() {
        isPrivacyShieldVisible = false
        didReachBackground = false
    }
    
    // MARK: - Configuration
    
    /// Update auto-hide delay
    @MainActor
    func setAutoHideDelay(_ delay: TimeInterval) {
        autoHideDelay = delay
        startAutoHideTimer()
    }
    
    /// Update decoy screen preference
    @MainActor
    func setDecoyScreen(_ type: DecoyScreenType) {
        decoyScreen = type
    }
}

// MARK: - Decoy Screen Type

enum DecoyScreenType: String, CaseIterable, Codable {
    case crossStitch = "Cross Stitch"
    case calculator = "Calculator"
    case weather = "Weather"
    case notes = "Notes"
    case voiceChanger = "Voice Changer"
    
    var icon: String {
        switch self {
        case .crossStitch: return "scissors"
        case .calculator: return "function"
        case .weather: return "cloud.sun.fill"
        case .notes: return "note.text"
        case .voiceChanger: return "mic.circle.fill"
        }
    }
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Stealth Mode Error

enum StealthModeError: LocalizedError {
    case authenticationUnavailable
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationUnavailable:
            return "Authentication is not available on this device"
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        }
    }
}
