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
    
    /// Track when app went to background
    private var didBackgroundAt: Date?
    
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
        // Listen for app entering background
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillResignActive()
        }
        
        // Listen for app entering foreground
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
        isStealthActive = true
        recordUserInteraction()
    }
    
    /// Deactivate stealth mode with authentication
    @MainActor
    func deactivateStealthMode() async throws {
        // Require biometric or passcode authentication
        try await authenticate()
        isStealthActive = false
        // Persist to UserDefaults immediately
        UserDefaults.standard.set(false, forKey: "isStealthModeActive")
        recordUserInteraction()
    }
    
    /// Quick hide (used for shake gesture or emergency)
    @MainActor
    func quickHide() {
        activateStealthMode(decoy: decoyScreen)
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
    
    private func handleAppWillResignActive() {
        // Always activate stealth mode when app goes to background for privacy protection
        didBackgroundAt = Date()
        // Execute synchronously on main thread to ensure state is updated before suspension
        MainActor.assumeIsolated {
            activateStealthMode()
        }
    }
    
    private func handleAppDidBecomeActive() {
        // Activate stealth mode when app comes to foreground if:
        // 1. App was in background (didBackgroundAt is set)
        // 2. It's been more than 1 second since background (not just a quick system interruption)
        if let backgroundTime = didBackgroundAt {
            let timeInBackground = Date().timeIntervalSince(backgroundTime)
            if timeInBackground > 1.0 {
                // Execute synchronously
                MainActor.assumeIsolated {
                    activateStealthMode()
                }
            }
            didBackgroundAt = nil
        }
        recordUserInteraction()
    }
    
    private func handleAppWillTerminate() {
        // Ensure stealth mode is active when app is force quit
        // This ensures the decoy screen is shown on next launch
        MainActor.assumeIsolated {
            isStealthActive = true
            UserDefaults.standard.set(true, forKey: "isStealthModeActive")
        }
    }
    
    /// Clear background tracking to prevent re-activation (used when unlocking)
    @MainActor
    func clearBackgroundTracking() {
        didBackgroundAt = nil
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
