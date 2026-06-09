import Foundation
import UserNotifications

/// Thin wrapper around UNUserNotificationCenter for the optional daily-card
/// reminder. All calls are safe to make whether or not authorization exists.
enum Notifications {
    private static let reminderID = "arcana.dailyReminder"

    enum AuthState {
        case authorized, denied, notDetermined
    }

    /// Current authorization, mapped to a small enum for the Settings UI.
    static func authorizationState() async -> AuthState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        default:
            return .notDetermined
        }
    }

    /// Requests authorization. Returns true if granted. Never throws to callers.
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedules (or replaces) the daily reminder at the given hour/minute.
    static func scheduleDaily(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])

        let content = UNMutableNotificationContent()
        content.title = "Your card awaits"
        content.body = "Draw your card of the day and set an intention."
        content.sound = .default

        var components = DateComponents()
        components.hour = min(max(hour, 0), 23)
        components.minute = min(max(minute, 0), 59)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    /// Cancels the daily reminder.
    static func cancelDaily() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}
