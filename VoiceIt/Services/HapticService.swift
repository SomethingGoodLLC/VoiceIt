import UIKit

/// Service for providing haptic feedback throughout the app
@MainActor
final class HapticService: Sendable {
    // MARK: - Singleton
    
    static let shared = HapticService()
    
    private init() {}
    
    // MARK: - Haptic Feedback
    
    /// Light impact feedback (for minor interactions)
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact feedback (for standard interactions)
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact feedback (for important actions)
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Success notification feedback
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification feedback
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification feedback
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Selection feedback (for picker-like interactions)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Specialized Feedback
    
    /// Emergency panic button feedback (strong pattern)
    func emergency() {
        let generator = UINotificationFeedbackGenerator()
        // Vibrate in a pattern
        generator.notificationOccurred(.warning)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            generator.notificationOccurred(.warning)
            try? await Task.sleep(nanoseconds: 200_000_000)
            generator.notificationOccurred(.error)
        }
    }
    
    /// Evidence saved feedback
    func evidenceSaved() {
        success()
    }
    
    /// Evidence deleted feedback
    func evidenceDeleted() {
        mediumImpact()
    }
    
    /// Stealth mode activated feedback
    func stealthActivated() {
        lightImpact()
    }
}
