import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    /// Add comprehensive accessibility labels for VoiceOver
    func voiceItAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        identifier: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
            .if(identifier != nil) { view in
                view.accessibilityIdentifier(identifier!)
            }
    }
    
    /// Mark as accessibility element with custom label
    func accessibilityElement(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Add accessibility action with custom name
    func accessibilityAction(
        named name: String,
        action: @escaping () -> Void
    ) -> some View {
        self.accessibilityAction(named: Text(name), action)
    }
    
    /// Mark as sensitive content (for password fields, etc.)
    func accessibilitySensitiveContent() -> some View {
        self
            .privacySensitive()
    }
    
    /// Group accessibility elements with label
    func accessibilityGroup(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }
    
    /// Conditional view modifier
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Dynamic Type Support

extension View {
    /// Ensure view supports Dynamic Type with proper scaling
    func dynamicTypeSupport(
        minScale: CGFloat = 0.8,
        maxScale: CGFloat = 2.0
    ) -> some View {
        self
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .minimumScaleFactor(minScale)
            .lineLimit(nil)
    }
    
    /// Apply accessibility-friendly spacing
    func accessibilitySpacing() -> some View {
        self.padding(.vertical, 2)
    }
}

// MARK: - Accessibility Traits Helpers

extension AccessibilityTraits {
    static let criticalEvidence: AccessibilityTraits = [.isButton, .isStaticText]
    static let emergencyButton: AccessibilityTraits = [.isButton, .startsMediaSession]
    static let navigationButton: AccessibilityTraits = [.isButton]
}

// MARK: - Accessibility Announcements

@MainActor
final class AccessibilityAnnouncer {
    static let shared = AccessibilityAnnouncer()
    
    private init() {}
    
    /// Post an accessibility announcement for VoiceOver users
    func announce(_ message: String, isImportant: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let notification: UIAccessibility.Notification = isImportant ? .screenChanged : .announcement
            UIAccessibility.post(notification: notification, argument: message)
        }
    }
    
    /// Announce evidence saved
    func announceEvidenceSaved(type: String) {
        announce("\(type) evidence saved successfully")
    }
    
    /// Announce evidence deleted
    func announceEvidenceDeleted() {
        announce("Evidence deleted")
    }
    
    /// Announce emergency activation
    func announceEmergency() {
        announce("Emergency mode activated", isImportant: true)
    }
    
    /// Announce stealth mode
    func announceStealthMode(activated: Bool) {
        announce(activated ? "Stealth mode activated" : "Stealth mode deactivated")
    }
    
    /// Announce authentication
    func announceAuthentication(success: Bool) {
        announce(success ? "Authentication successful" : "Authentication failed")
    }
}
