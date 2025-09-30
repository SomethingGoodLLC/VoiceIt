import SwiftUI

extension Color {
    // MARK: - Primary Colors
    
    /// Voice It primary purple
    static let voiceitPurple = Color(hex: "7C3AED")
    
    /// Voice It secondary purple (lighter)
    static let voiceitPurpleLight = Color(hex: "A78BFA")
    
    /// Voice It secondary purple (darker)
    static let voiceitPurpleDark = Color(hex: "5B21B6")
    
    // MARK: - Gradient Functions
    
    /// Purple to pink gradient
    static var voiceitGradient: LinearGradient {
        LinearGradient(
            colors: [voiceitPurple, Color(hex: "EC4899")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Purple to blue gradient
    static var voiceitGradientCool: LinearGradient {
        LinearGradient(
            colors: [voiceitPurple, Color(hex: "3B82F6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Semantic Colors
    
    /// Success/positive color
    static let voiceitSuccess = Color(hex: "10B981")
    
    /// Warning color
    static let voiceitWarning = Color(hex: "F59E0B")
    
    /// Error/danger color
    static let voiceitError = Color(hex: "EF4444")
    
    /// Critical/emergency color
    static let voiceitCritical = Color(hex: "DC2626")
    
    // MARK: - Background Colors
    
    /// Primary background
    static let voiceitBackground = Color(.systemBackground)
    
    /// Secondary background
    static let voiceitBackgroundSecondary = Color(.secondarySystemBackground)
    
    /// Tertiary background
    static let voiceitBackgroundTertiary = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors
    
    /// Primary text
    static let voiceitText = Color(.label)
    
    /// Secondary text
    static let voiceitTextSecondary = Color(.secondaryLabel)
    
    /// Tertiary text
    static let voiceitTextTertiary = Color(.tertiaryLabel)
    
    // MARK: - Hex Initializer
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    /// Emergency gradient (red to orange)
    static var emergency: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "DC2626"), Color(hex: "F59E0B")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Success gradient (green to teal)
    static var success: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "10B981"), Color(hex: "14B8A6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
