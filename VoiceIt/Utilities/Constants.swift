import Foundation
import SwiftUI

/// App-wide constants
enum Constants {
    // MARK: - App Info
    
    enum App {
        static let name = "Voice It"
        static let version = "1.0.0"
        static let build = "1"
    }
    
    // MARK: - Files & Storage
    
    enum Storage {
        static let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        
        static let evidenceDirectory = documentsDirectory.appendingPathComponent("Evidence")
        static let audioDirectory = evidenceDirectory.appendingPathComponent("Audio")
        static let photoDirectory = evidenceDirectory.appendingPathComponent("Photos")
        static let videoDirectory = evidenceDirectory.appendingPathComponent("Videos")
        static let exportsDirectory = documentsDirectory.appendingPathComponent("Exports")
        
        static let maxAudioDuration: TimeInterval = 3600 // 1 hour
        static let maxVideoSize: Int64 = 500_000_000 // 500 MB
        static let maxPhotoSize: Int64 = 25_000_000 // 25 MB
    }
    
    // MARK: - Security
    
    enum Security {
        static let autoLockTimeout: TimeInterval = 300 // 5 minutes
        static let maxLoginAttempts = 5
        static let lockoutDuration: TimeInterval = 900 // 15 minutes
        static let minPasscodeLength = 4
    }
    
    // MARK: - Location
    
    enum Location {
        static let defaultSearchRadius: Double = 50_000 // 50km
        static let maxSearchRadius: Double = 100_000 // 100km
        static let highAccuracyThreshold: Double = 10 // meters
        static let lowAccuracyThreshold: Double = 100 // meters
    }
    
    // MARK: - Export
    
    enum Export {
        static let pdfPageWidth: CGFloat = 612 // US Letter width
        static let pdfPageHeight: CGFloat = 792 // US Letter height
        static let pdfMargin: CGFloat = 50
        static let maxExportItems = 1000
    }
    
    // MARK: - Emergency
    
    enum Emergency {
        static let emergencyNumber = "911"
        static let maxEmergencyContacts = 10
        static let autoNotifyDelaySeconds: TimeInterval = 5 // Countdown before auto-notify
    }
    
    // MARK: - UI
    
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let animationDuration: Double = 0.3
        static let hapticFeedback = true
        
        // Padding
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 16
        static let paddingLarge: CGFloat = 24
        
        // Icon sizes
        static let iconSmall: CGFloat = 20
        static let iconMedium: CGFloat = 28
        static let iconLarge: CGFloat = 44
    }
    
    // MARK: - Network
    
    enum Network {
        static let requestTimeout: TimeInterval = 30
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 2
    }
    
    // MARK: - API Configuration
    
    enum API {
        static let baseURL = "https://voiceitnow.org"
        
        // Endpoints
        enum Endpoints {
            // Authentication
            static let signup = "/api/auth/signup"
            static let login = "/api/auth/login"
            static let logout = "/api/auth/logout"
            static let verifyToken = "/api/auth/verify"
            static let forgotPassword = "/api/auth/forgot-password"
            static let resetPassword = "/api/auth/reset-password"
            
            // Timeline
            static let timelineEntries = "/api/timeline/entries"
            
            // Waitlist
            static let waitlist = "/api/app/waitlist"
        }
    }
    
    // MARK: - Hotlines (National - US)
    
    enum Hotlines {
        static let domesticViolence = "1-800-799-7233"
        static let crisisText = "741741" // Text HOME to this number
        static let sexualAssault = "1-800-656-4673"
        static let suicide = "988"
        static let childAbuse = "1-800-422-4453"
    }
}

// MARK: - Create Directories

extension Constants.Storage {
    /// Create all required directories
    static func createDirectories() throws {
        let directories = [
            evidenceDirectory,
            audioDirectory,
            photoDirectory,
            videoDirectory,
            exportsDirectory
        ]
        
        for directory in directories {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        }
    }
}

