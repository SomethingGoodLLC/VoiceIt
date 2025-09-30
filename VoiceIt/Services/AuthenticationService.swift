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
    
    // MARK: - Initialization
    
    init() {
        checkBiometricAvailability()
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
    
    /// Authenticate using biometrics or passcode
    func authenticate(reason: String = "Authenticate to access Voice It") async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Enter Passcode"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
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
    
    /// Set app passcode (separate from device passcode)
    func setPasscode(_ passcode: String) throws {
        guard passcode.count >= 4 else {
            throw AuthenticationError.passcodeTooShort
        }
        
        guard let data = passcode.data(using: .utf8) else {
            throw AuthenticationError.invalidPasscode
        }
        
        try keychainManager.save(data, key: .appPasscode)
    }
    
    /// Verify app passcode
    func verifyPasscode(_ passcode: String) throws -> Bool {
        guard let storedData = try? keychainManager.retrieve(key: .appPasscode),
              let storedPasscode = String(data: storedData, encoding: .utf8) else {
            return false
        }
        
        return passcode == storedPasscode
    }
    
    /// Remove app passcode
    func removePasscode() throws {
        try keychainManager.delete(key: .appPasscode)
    }
    
    // MARK: - Auto-Lock
    
    /// Check if app should auto-lock based on last activity
    func shouldAutoLock(lastActivity: Date, timeout: TimeInterval = 300) -> Bool {
        // Default 5 minutes
        return Date().timeIntervalSince(lastActivity) > timeout
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
    case invalidPasscode
    case passcodeNotSet
    
    var errorDescription: String? {
        switch self {
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .passcodeTooShort:
            return "Passcode must be at least 4 characters"
        case .invalidPasscode:
            return "Invalid passcode"
        case .passcodeNotSet:
            return "No passcode has been set"
        }
    }
}
