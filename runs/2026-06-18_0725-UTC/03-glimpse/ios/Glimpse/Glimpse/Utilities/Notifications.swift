import Foundation
import UserNotifications

/// Wraps the daily "capture today's glimpse" reminder. Permission is requested
/// politely and only one repeating notification is ever pending (cap enforced).
@MainActor
enum ReminderManager {
    private static let identifier = "glimpse.daily.reminder"

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                cont.resume(returning: settings.authorizationStatus)
            }
        }
    }

    /// Requests permission if not yet determined. Returns whether notifications
    /// are allowed afterwards.
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await authorizationStatus()
        switch status {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            return granted
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    /// Schedules (or replaces) the single daily reminder at the given time.
    static func schedule(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Today's glimpse"
        content.body = "Capture one moment from today before it slips away."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = min(max(hour, 0), 23)
        comps.minute = min(max(minute, 0), 59)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
