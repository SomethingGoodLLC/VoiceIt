import Foundation
import Security

/// Manager for secure keychain operations
final class KeychainManager: @unchecked Sendable {
    // MARK: - Singleton
    
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Save
    
    /// Save data to keychain
    func save(_ data: Data, key: KeychainKey) throws {
        // Delete any existing item
        try? delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    // MARK: - Retrieve
    
    /// Retrieve data from keychain
    func retrieve(key: KeychainKey) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    // MARK: - Update
    
    /// Update existing keychain item
    func update(_ data: Data, key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            // If item doesn't exist, save it
            if status == errSecItemNotFound {
                try save(data, key: key)
                return
            }
            throw KeychainError.updateFailed(status)
        }
    }
    
    // MARK: - Delete
    
    /// Delete keychain item
    func delete(key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Clear All
    
    /// Clear all keychain items for this app
    func clearAll() throws {
        for key in KeychainKey.allCases {
            try? delete(key: key)
        }
    }
}

// MARK: - Keychain Key

enum KeychainKey: String, CaseIterable {
    case masterEncryptionKey = "com.voiceit.encryption.masterKey"
    case appPasscode = "com.voiceit.auth.passcode"
    case biometricEnabled = "com.voiceit.auth.biometric"
}

// MARK: - Keychain Error

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case updateFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain (status: \(status))"
        case .updateFailed(let status):
            return "Failed to update keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from keychain (status: \(status))"
        case .invalidData:
            return "Invalid data format in keychain"
        }
    }
}
