import UIKit
import Observation

/// Service for managing alternate app icons for disguise
@Observable
final class AppIconService: @unchecked Sendable {
    // MARK: - Shared Instance
    
    @MainActor
    static let shared = AppIconService()
    
    // MARK: - Properties
    
    /// Current app icon
    @MainActor
    var currentIcon: AppIcon = .default
    
    /// Whether changing icons is supported
    @MainActor
    var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }
    
    // MARK: - Initialization
    
    @MainActor
    private init() {
        updateCurrentIcon()
    }
    
    // MARK: - Helper
    
    @MainActor
    private func updateCurrentIcon() {
        if let iconName = UIApplication.shared.alternateIconName {
            currentIcon = AppIcon.allCases.first { $0.rawValue == iconName } ?? .default
        } else {
            currentIcon = .default
        }
    }
    
    // MARK: - Change Icon
    
    /// Change the app icon
    @MainActor
    func changeIcon(to icon: AppIcon) async throws {
        guard supportsAlternateIcons else {
            print("📛 AppIconService: Alternate icons not supported")
            throw AppIconError.notSupported
        }
        
        let iconName = icon == .default ? nil : icon.rawValue
        
        print("📱 AppIconService: Attempting to change icon to '\(iconName ?? "default")'")
        
        do {
            try await UIApplication.shared.setAlternateIconName(iconName)
            updateCurrentIcon()
            
            print("✅ AppIconService: Successfully changed icon to '\(iconName ?? "default")'")
            
            // Provide haptic feedback
            HapticService.shared.success()
        } catch {
            print("❌ AppIconService: Failed to change icon - \(error.localizedDescription)")
            // Update anyway just in case
            updateCurrentIcon()
            throw error
        }
    }
}

// MARK: - App Icon

enum AppIcon: String, CaseIterable, Hashable {
    case `default` = "AppIcon"
    case crossStitch = "CrossStitch"
    case calculator = "Calculator"
    case weather = "Weather"
    case notes = "Notes"
    case wellness = "Wellness"
    
    var displayName: String {
        switch self {
        case .default:
            return "Voice It"
        case .crossStitch:
            return "My Patterns"
        case .calculator:
            return "Calculator"
        case .weather:
            return "Weather"
        case .notes:
            return "My Notes"
        case .wellness:
            return "Wellness Journal"
        }
    }
    
    var description: String {
        switch self {
        case .default:
            return "Standard app icon"
        case .crossStitch:
            return "Disguise as a cross-stitch app"
        case .calculator:
            return "Disguise as a calculator app"
        case .weather:
            return "Disguise as a weather app"
        case .notes:
            return "Disguise as a notes app"
        case .wellness:
            return "Disguise as a wellness journal"
        }
    }
    
    var previewIcon: String {
        switch self {
        case .default:
            return "waveform.circle.fill"
        case .crossStitch:
            return "scissors"
        case .calculator:
            return "plusminus.circle.fill"
        case .weather:
            return "cloud.sun.fill"
        case .notes:
            return "note.text"
        case .wellness:
            return "heart.circle.fill"
        }
    }
}

// MARK: - App Icon Error

enum AppIconError: LocalizedError {
    case notSupported
    case changeFailed
    
    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "This device does not support changing app icons"
        case .changeFailed:
            return "Failed to change app icon"
        }
    }
}
