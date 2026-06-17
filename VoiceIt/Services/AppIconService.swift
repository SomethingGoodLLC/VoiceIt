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
    
    private static let retryBackoffNanoseconds: [UInt64] = [
        500_000_000,
        1_500_000_000,
        3_000_000_000
    ]
    
    /// One-shot observer used to retry the icon change the next time the app
    /// becomes active, as a best-effort mitigation for the iOS 26.1+ regression.
    @MainActor
    private var pendingActiveRetryObserver: NSObjectProtocol?
    
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
    
    /// Waits (up to a short timeout) for the app to become active before changing the icon.
    /// iOS rejects icon changes while inactive, but we must not block forever if the app
    /// stays inactive (e.g. Control Center or a system alert is on screen).
    @MainActor
    private func waitForActiveApplication() async {
        let maxAttempts = 20 // ~2 seconds at 100ms per attempt
        var attempts = 0
        while UIApplication.shared.applicationState != .active, attempts < maxAttempts {
            try? await Task.sleep(nanoseconds: 100_000_000)
            attempts += 1
        }
    }
    
    private static func isRetryableIconChangeError(_ error: NSError) -> Bool {
        if error.domain == NSPOSIXErrorDomain && error.code == 35 {
            return true
        }
        if error.code == 3072 {
            return true
        }
        return error.localizedDescription.localizedCaseInsensitiveContains("temporarily unavailable")
    }
    
    @MainActor
    private func setAlternateIcon(_ iconName: String?) async throws {
        await waitForActiveApplication()
        
        // iOS 26.1+ mitigation: LSIconAlertManager needs a presentation context to
        // acquire the system "icon changed" alert token. Briefly present an empty,
        // transparent view controller so that context exists, then tear it down.
        let transientContext = presentTransientContext()
        defer { transientContext?.dismiss(animated: false) }
        
        try await UIApplication.shared.setAlternateIconName(iconName)
    }
    
    /// Presents an empty transparent view controller on the foreground window to give
    /// the system icon-change alert a presentation context. Returns it so the caller
    /// can dismiss it. Returns nil if no suitable window is found (call proceeds anyway).
    @MainActor
    private func presentTransientContext() -> UIViewController? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = windowScenes.first(where: { $0.activationState == .foregroundActive }) ?? windowScenes.first,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first,
              let root = window.rootViewController else {
            return nil
        }
        
        var topmost = root
        while let presented = topmost.presentedViewController {
            topmost = presented
        }
        
        let placeholder = UIViewController()
        placeholder.view.backgroundColor = .clear
        placeholder.modalPresentationStyle = .overFullScreen
        topmost.present(placeholder, animated: false)
        return placeholder
    }
    
    /// Best-effort: retry the icon change once the next time the app becomes active.
    /// Many iOS 26.1+ failures resolve after the app returns to the foreground.
    @MainActor
    private func scheduleRetryOnNextActive(iconName: String?) {
        if let existing = pendingActiveRetryObserver {
            NotificationCenter.default.removeObserver(existing)
            pendingActiveRetryObserver = nil
        }
        
        print("🕓 AppIconService: Scheduling icon retry on next app activation")
        pendingActiveRetryObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if let observer = self.pendingActiveRetryObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self.pendingActiveRetryObserver = nil
                }
                do {
                    try await self.setAlternateIcon(iconName)
                    self.updateCurrentIcon()
                    print("✅ AppIconService: Icon applied on next app activation")
                    HapticService.shared.success()
                } catch {
                    print("❌ AppIconService: Deferred icon retry failed: \(error.localizedDescription)")
                }
            }
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
        
        // Check if already on this icon
        if icon == currentIcon {
            print("ℹ️ AppIconService: Already using '\(icon.rawValue)' icon")
            return
        }
        
        let iconName = icon == .default ? nil : icon.rawValue
        
        print("📱 AppIconService: Attempting to change icon to '\(iconName ?? "default")'")
        
        // Small delay to ensure app is in stable state
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        var lastError: NSError?
        
        for attempt in 0...Self.retryBackoffNanoseconds.count {
            do {
                try await setAlternateIcon(iconName)
                updateCurrentIcon()
                
                if attempt > 0 {
                    print("✅ AppIconService: Successfully changed icon on retry \(attempt)")
                } else {
                    print("✅ AppIconService: Successfully changed icon to '\(iconName ?? "default")'")
                }
                
                HapticService.shared.success()
                return
            } catch let error as NSError {
                lastError = error
                print("❌ AppIconService: Failed to change icon - \(error.localizedDescription)")
                print("❌ Error code: \(error.code), domain: \(error.domain)")
                
                guard attempt < Self.retryBackoffNanoseconds.count,
                      Self.isRetryableIconChangeError(error) else {
                    break
                }
                
                let delay = Self.retryBackoffNanoseconds[attempt]
                print("⏳ AppIconService: Resource unavailable, waiting and retrying...")
                try? await Task.sleep(nanoseconds: delay)
            }
        }
        
        updateCurrentIcon()
        
        // If this is the known iOS 26.1+ system regression, surface a friendly error
        // and schedule a best-effort retry for the next time the app becomes active.
        if let lastError, Self.isRetryableIconChangeError(lastError) {
            scheduleRetryOnNextActive(iconName: iconName)
            throw AppIconError.systemUnavailable
        }
        
        throw lastError ?? AppIconError.changeFailed
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
    case voiceChanger = "VoiceChanger"
    
    /// Alternate icons declared in Info.plist (excludes primary AppIcon).
    static var registeredAlternateIconNames: [String] {
        allCases
            .filter { $0 != .default }
            .map(\.rawValue)
    }
    
    /// Maps stealth decoy screens to their matching alternate app icon.
    static func forDecoy(_ decoy: DecoyScreenType) -> AppIcon {
        switch decoy {
        case .calculator:
            return .calculator
        case .notes:
            return .notes
        case .crossStitch:
            return .crossStitch
        case .weather:
            return .weather
        case .voiceChanger:
            return .voiceChanger
        }
    }
    
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
        case .voiceChanger:
            return "Voice It FX"
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
        case .voiceChanger:
            return "Disguise as a voice changer app"
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
        case .voiceChanger:
            return "mic.circle.fill"
        }
    }
}

// MARK: - App Icon Error

enum AppIconError: LocalizedError {
    case notSupported
    case changeFailed
    case systemUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "This device does not support changing app icons"
        case .changeFailed:
            return "Failed to change app icon"
        case .systemUnavailable:
            return "iOS couldn't update the home-screen icon right now. This is a known issue on this iOS version — restarting your device usually fixes it. Your decoy screen is already set and working."
        }
    }
}
