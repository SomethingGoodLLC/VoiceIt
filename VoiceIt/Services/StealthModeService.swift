import Foundation
import SwiftUI
import Observation
import LocalAuthentication

/// Service for managing stealth mode with decoy screens
@Observable
final class StealthModeService: @unchecked Sendable {
    // MARK: - Properties
    
    /// Whether stealth mode is currently active
    var isStealthActive = false
    
    /// Selected decoy screen type
    var decoyScreen: DecoyScreenType = .calculator
    
    /// Auto-hide after inactivity (in seconds, 0 = disabled)
    var autoHideDelay: TimeInterval = 0
    
    /// Last user interaction timestamp
    private var lastInteraction = Date()
    
    /// Auto-hide timer
    private var autoHideTimer: Timer?
    
    /// Whether to hide app icon (requires app restart)
    var hideAppIcon = false
    
    /// Authentication context
    private let authContext = LAContext()
    
    // MARK: - Initialization
    
    init() {
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
    
    /// Activate stealth mode
    @MainActor
    func activateStealthMode(decoy: DecoyScreenType = .calculator) {
        decoyScreen = decoy
        isStealthActive = true
        recordUserInteraction()
    }
    
    /// Deactivate stealth mode with authentication
    @MainActor
    func deactivateStealthMode() async throws {
        // Require biometric or passcode authentication
        try await authenticate()
        isStealthActive = false
        recordUserInteraction()
    }
    
    /// Quick hide (used for shake gesture or emergency)
    @MainActor
    func quickHide() {
        activateStealthMode(decoy: decoyScreen)
    }
    
    // MARK: - Authentication
    
    /// Authenticate user with biometrics or passcode
    private func authenticate() async throws {
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
        // Optionally activate stealth mode when app goes to background
        // This can be toggled in settings
        if hideAppIcon {
            Task { @MainActor in
                activateStealthMode()
            }
        }
    }
    
    private func handleAppDidBecomeActive() {
        // Require authentication when app comes back to foreground
        // if stealth mode was active
        recordUserInteraction()
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
    case calculator = "Calculator"
    case weather = "Weather"
    case notes = "Notes"
    
    var icon: String {
        switch self {
        case .calculator: return "function"
        case .weather: return "cloud.sun.fill"
        case .notes: return "note.text"
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
