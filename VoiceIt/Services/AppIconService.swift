import UIKit
import Observation

/// Service for managing alternate app icons for disguise
@Observable
final class AppIconService: @unchecked Sendable {
    // MARK: - Properties
    
    /// Current app icon
    var currentIcon: AppIcon {
        guard let iconName = UIApplication.shared.alternateIconName else {
            return .default
        }
        return AppIcon.allCases.first { $0.rawValue == iconName } ?? .default
    }
    
    /// Whether changing icons is supported
    var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }
    
    // MARK: - Change Icon
    
    /// Change the app icon
    @MainActor
    func changeIcon(to icon: AppIcon) async throws {
        guard supportsAlternateIcons else {
            throw AppIconError.notSupported
        }
        
        let iconName = icon == .default ? nil : icon.rawValue
        
        try await UIApplication.shared.setAlternateIconName(iconName)
        
        // Provide haptic feedback
        HapticService.shared.success()
    }
}

// MARK: - App Icon

enum AppIcon: String, CaseIterable, Hashable {
    case `default` = "AppIcon"
    case calculator = "Calculator"
    case weather = "Weather"
    case notes = "Notes"
    case wellness = "Wellness"
    
    var displayName: String {
        switch self {
        case .default:
            return "Voice It"
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
