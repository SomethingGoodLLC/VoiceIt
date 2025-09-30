import Foundation
import LocalAuthentication
import Observation

/// Service for biometric authentication and passcode security
@Observable
final class AuthenticationService: @unchecked Sendable {
    // MARK: - Properties
    
    private let context = LAContext()
    private let keychainManager = KeychainManager.shared
    
    /// Authentication state
    var isAuthenticated = false
    
    /// Biometric type available
    var biometricType: BiometricType = .none
    
    /// Error if authentication fails
    var authenticationError: AuthenticationError?
    
    /// Failed authentication attempts counter
    private(set) var failedAttempts: Int = 0
    
    /// Lock timestamp after biometric failure
    private(set) var lockedUntil: Date?
    
    /// Last activity timestamp for auto-lock
    var lastActivityDate: Date = Date()
    
    /// Auto-lock timeout in seconds (default 5 minutes)
    @ObservationIgnored
    var autoLockTimeout: TimeInterval {
        get {
            UserDefaults.standard.double(forKey: "autoLockTimeout").isZero ? 300 : UserDefaults.standard.double(forKey: "autoLockTimeout")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoLockTimeout")
        }
    }
    
    /// Whether biometric authentication is enabled
    @ObservationIgnored
    var isBiometricEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isBiometricEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isBiometricEnabled")
        }
    }
    
    // MARK: - Initialization
    
    init() {
        checkBiometricAvailability()
        // Enable biometrics by default if available
        if biometricType != .none && !UserDefaults.standard.bool(forKey: "hasSetBiometric") {
            isBiometricEnabled = true
            UserDefaults.standard.set(true, forKey: "hasSetBiometric")
        }
    }
    
    // MARK: - Biometric Availability
    
    /// Check what biometric authentication is available
    private func checkBiometricAvailability() {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }
        
        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
        case .touchID:
            biometricType = .touchID
        case .opticID:
            biometricType = .opticID
        case .none:
            biometricType = .none
        @unknown default:
            biometricType = .none
        }
    }
    
    // MARK: - Authentication
    
    /// Check if currently locked due to failed attempts
    func isCurrentlyLocked() -> Bool {
        guard let lockedUntil = lockedUntil else { return false }
        return Date() < lockedUntil
    }
    
    /// Remaining lock time in seconds
    func remainingLockTime() -> TimeInterval {
        guard let lockedUntil = lockedUntil else { return 0 }
        return max(0, lockedUntil.timeIntervalSinceNow)
    }
    
    /// Authenticate using biometrics or passcode
    func authenticate(reason: String = "Authenticate to access Voice It") async throws {
        // Check if locked
        if isCurrentlyLocked() {
            throw AuthenticationError.temporarilyLocked(Int(remainingLockTime()))
        }
        
        // Check if too many failed attempts
        if failedAttempts >= 5 {
            throw AuthenticationError.tooManyAttempts
        }
        
        let context = LAContext()
        context.localizedCancelTitle = "Enter Passcode"
        
        do {
            let success = try await context.evaluatePolicy(
                isBiometricEnabled ? .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isAuthenticated = success
                self.authenticationError = nil
                self.failedAttempts = 0 // Reset on success
                self.lockedUntil = nil
                self.lastActivityDate = Date()
            }
        } catch let error as LAError {
            await handleAuthenticationFailure(error: error)
            throw AuthenticationError.authenticationFailed(error.localizedDescription)
        }
    }
    
    /// Handle authentication failure with appropriate locking
    private func handleAuthenticationFailure(error: LAError) async {
        await MainActor.run {
            self.isAuthenticated = false
            self.failedAttempts += 1
            self.authenticationError = .authenticationFailed(error.localizedDescription)
            
            // Lock after biometric failure (1 minute), then passcode only
            if error.code == .biometryLockout || error.code == .biometryNotAvailable {
                self.lockedUntil = Date().addingTimeInterval(60) // 1 minute lock
            }
            
            // After 5 failed attempts, require account recovery
            if self.failedAttempts >= 5 {
                self.authenticationError = .tooManyAttempts
            }
        }
    }
    
    /// Authenticate with biometrics only (no passcode fallback)
    func authenticateWithBiometrics(reason: String = "Use biometrics to unlock") async throws {
        guard biometricType != .none else {
            throw AuthenticationError.biometricsNotAvailable
        }
        
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isAuthenticated = success
                self.authenticationError = nil
            }
        } catch let error as LAError {
            await MainActor.run {
                self.isAuthenticated = false
                self.authenticationError = .authenticationFailed(error.localizedDescription)
            }
            throw AuthenticationError.authenticationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Passcode Management
    
    /// Set app passcode (requires 6 digits minimum)
    func setPasscode(_ passcode: String) throws {
        guard passcode.count >= 6 else {
            throw AuthenticationError.passcodeTooShort
        }
        
        // Validate it's numeric
        guard passcode.allSatisfy({ $0.isNumber }) else {
            throw AuthenticationError.passcodeNotNumeric
        }
        
        guard let data = passcode.data(using: .utf8) else {
            throw AuthenticationError.invalidPasscode
        }
        
        try keychainManager.save(data, key: .appPasscode)
    }
    
    /// Verify app passcode
    func verifyPasscode(_ passcode: String) throws -> Bool {
        // Check if locked
        if isCurrentlyLocked() {
            throw AuthenticationError.temporarilyLocked(Int(remainingLockTime()))
        }
        
        // Check if too many failed attempts
        if failedAttempts >= 5 {
            throw AuthenticationError.tooManyAttempts
        }
        
        guard let storedData = try? keychainManager.retrieve(key: .appPasscode),
              let storedPasscode = String(data: storedData, encoding: .utf8) else {
            return false
        }
        
        let isValid = passcode == storedPasscode
        
        if isValid {
            failedAttempts = 0
            lockedUntil = nil
            isAuthenticated = true
            lastActivityDate = Date()
        } else {
            failedAttempts += 1
            if failedAttempts >= 5 {
                authenticationError = .tooManyAttempts
            }
        }
        
        return isValid
    }
    
    /// Remove app passcode
    func removePasscode() throws {
        try keychainManager.delete(key: .appPasscode)
    }
    
    /// Reset failed attempts (for account recovery)
    func resetFailedAttempts() {
        failedAttempts = 0
        lockedUntil = nil
        authenticationError = nil
    }
    
    /// Update last activity timestamp
    func updateActivity() {
        lastActivityDate = Date()
    }
    
    // MARK: - Auto-Lock
    
    /// Check if app should auto-lock based on last activity
    func shouldAutoLock() -> Bool {
        return Date().timeIntervalSince(lastActivityDate) > autoLockTimeout
    }
    
    /// Log out / lock the app
    func lockApp() {
        isAuthenticated = false
    }
}

// MARK: - Biometric Type

enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }
    
    var icon: String {
        switch self {
        case .none:
            return "lock.fill"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .opticID:
            return "opticid"
        }
    }
}

// MARK: - Authentication Error

enum AuthenticationError: LocalizedError {
    case biometricsNotAvailable
    case authenticationFailed(String)
    case passcodeTooShort
    case passcodeNotNumeric
    case invalidPasscode
    case passcodeNotSet
    case temporarilyLocked(Int) // seconds remaining
    case tooManyAttempts
    
    var errorDescription: String? {
        switch self {
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .passcodeTooShort:
            return "Passcode must be at least 6 digits"
        case .passcodeNotNumeric:
            return "Passcode must contain only numbers"
        case .invalidPasscode:
            return "Invalid passcode"
        case .passcodeNotSet:
            return "No passcode has been set"
        case .temporarilyLocked(let seconds):
            return "Too many failed attempts. Locked for \(seconds) seconds."
        case .tooManyAttempts:
            return "Too many failed attempts. Please reset your passcode via account recovery."
        }
    }
}
