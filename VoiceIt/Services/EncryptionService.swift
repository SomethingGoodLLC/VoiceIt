import Foundation
import CryptoKit

/// Service for handling end-to-end encryption using CryptoKit
final class EncryptionService: Sendable {
    // MARK: - Properties
    
    private let keychainManager = KeychainManager.shared
    
    // MARK: - Encryption Key Management
    
    /// Get or create the master encryption key
    private func getMasterKey() throws -> SymmetricKey {
        // Try to retrieve existing key from keychain
        if let keyData = try? keychainManager.retrieve(key: .masterEncryptionKey) {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key if none exists
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        try keychainManager.save(keyData, key: .masterEncryptionKey)
        
        return key
    }
    
    // MARK: - Data Encryption
    
    /// Encrypt data using AES-GCM-256
    func encrypt(_ data: Data) async throws -> Data {
        let key = try getMasterKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return combined
    }
    
    /// Decrypt data using AES-GCM-256
    func decrypt(_ encryptedData: Data) async throws -> Data {
        let key = try getMasterKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return decryptedData
    }
    
    // MARK: - File Encryption
    
    /// Encrypt file at path and return encrypted file path
    func encryptFile(at sourcePath: URL) async throws -> URL {
        let data = try Data(contentsOf: sourcePath)
        let encryptedData = try await encrypt(data)
        
        // Create encrypted file path
        let encryptedPath = sourcePath
            .deletingPathExtension()
            .appendingPathExtension("encrypted")
        
        try encryptedData.write(to: encryptedPath)
        
        return encryptedPath
    }
    
    /// Decrypt file at path and return decrypted file path
    func decryptFile(at sourcePath: URL) async throws -> URL {
        let encryptedData = try Data(contentsOf: sourcePath)
        let decryptedData = try await decrypt(encryptedData)
        
        // Create decrypted file path (remove .encrypted extension)
        let decryptedPath = sourcePath.deletingPathExtension()
        
        try decryptedData.write(to: decryptedPath)
        
        return decryptedPath
    }
    
    // MARK: - String Encryption
    
    /// Encrypt string
    func encrypt(_ string: String) async throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        
        let encryptedData = try await encrypt(data)
        return encryptedData.base64EncodedString()
    }
    
    /// Decrypt string
    func decrypt(_ encryptedString: String) async throws -> String {
        guard let data = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.invalidInput
        }
        
        let decryptedData = try await decrypt(data)
        
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        return string
    }
    
    // MARK: - Key Rotation
    
    /// Rotate the master encryption key (re-encrypt all data with new key)
    func rotateMasterKey() async throws {
        // This is a placeholder for key rotation logic
        // In production, this would:
        // 1. Generate new key
        // 2. Retrieve all encrypted data
        // 3. Decrypt with old key
        // 4. Re-encrypt with new key
        // 5. Save new key
        throw EncryptionError.notImplemented
    }
    
    // MARK: - Secure Delete
    
    /// Securely delete a file by overwriting it multiple times before deletion
    func secureDelete(at path: URL) async throws {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path.path) else {
            throw EncryptionError.invalidInput
        }
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: path.path)
        guard let fileSize = attributes[.size] as? Int else {
            throw EncryptionError.invalidInput
        }
        
        // Overwrite file 3 times with random data
        for _ in 0..<3 {
            var randomData = Data(count: fileSize)
            randomData.withUnsafeMutableBytes { bufferPointer in
                guard let baseAddress = bufferPointer.baseAddress else { return }
                _ = SecRandomCopyBytes(kSecRandomDefault, fileSize, baseAddress)
            }
            
            try randomData.write(to: path, options: .atomic)
        }
        
        // Finally delete the file
        try fileManager.removeItem(at: path)
    }
    
    /// Securely delete data from memory (overwrite with zeros)
    func secureErase(_ data: inout Data) {
        let count = data.count
        data.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            memset(baseAddress, 0, count)
        }
        data = Data()
    }
    
    // MARK: - Hash Functions
    
    /// Generate SHA-256 hash of data
    func hash(_ data: Data) -> Data {
        let digest = SHA256.hash(data: data)
        return Data(digest)
    }
    
    /// Generate SHA-256 hash of string
    func hash(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Encryption Error

enum EncryptionError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidInput
    case keyGenerationFailed
    case keyNotFound
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidInput:
            return "Invalid input data"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .keyNotFound:
            return "Encryption key not found"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}
