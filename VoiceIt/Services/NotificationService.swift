import Foundation
import UserNotifications
import Observation

/// Service for managing notifications with privacy-focused content
@Observable
final class NotificationService: @unchecked Sendable {
    // MARK: - Properties
    
    /// Whether notifications are enabled
    private(set) var areNotificationsEnabled = false
    
    /// Notification content style
    @ObservationIgnored
    var contentStyle: NotificationContentStyle {
        get {
            let rawValue = UserDefaults.standard.integer(forKey: "notificationContentStyle")
            return NotificationContentStyle(rawValue: rawValue) ?? .generic
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "notificationContentStyle")
        }
    }
    
    // MARK: - Initialization
    
    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Request notification permission
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        
        await MainActor.run {
            self.areNotificationsEnabled = granted
        }
    }
    
    /// Check current authorization status
    @MainActor
    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        areNotificationsEnabled = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule a notification for evidence reminder
    func scheduleEvidenceReminder(date: Date) async throws {
        let content = UNMutableNotificationContent()
        
        switch contentStyle {
        case .generic:
            content.title = "Reminder"
            content.body = "You have a reminder"
        case .vague:
            content.title = "Daily Check-in"
            content.body = "Time for your daily check-in"
        case .specific:
            content.title = "Evidence Reminder"
            content.body = "Don't forget to document today"
        }
        
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    /// Schedule export reminder
    func scheduleExportReminder(days: Int) async throws {
        let content = UNMutableNotificationContent()
        
        switch contentStyle {
        case .generic:
            content.title = "Reminder"
            content.body = "You have a pending task"
        case .vague:
            content.title = "Weekly Review"
            content.body = "Time for your weekly review"
        case .specific:
            content.title = "Export Reminder"
            content.body = "Consider backing up your evidence"
        }
        
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(days * 86400), repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "export-reminder",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    /// Remove all pending notifications
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Remove specific notification
    func removeNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// MARK: - Notification Content Style

enum NotificationContentStyle: Int, CaseIterable {
    case generic = 0    // "Reminder" - most private
    case vague = 1      // "Daily Check-in" - somewhat descriptive
    case specific = 2   // "Evidence Reminder" - descriptive
    
    var displayName: String {
        switch self {
        case .generic:
            return "Generic"
        case .vague:
            return "Vague"
        case .specific:
            return "Specific"
        }
    }
    
    var description: String {
        switch self {
        case .generic:
            return "\"Reminder\" - Maximum privacy"
        case .vague:
            return "\"Daily Check-in\" - Moderate privacy"
        case .specific:
            return "\"Evidence Reminder\" - Clear but less private"
        }
    }
    
    var example: String {
        switch self {
        case .generic:
            return "Reminder: You have a reminder"
        case .vague:
            return "Daily Check-in: Time for your daily check-in"
        case .specific:
            return "Evidence Reminder: Don't forget to document today"
        }
    }
}
