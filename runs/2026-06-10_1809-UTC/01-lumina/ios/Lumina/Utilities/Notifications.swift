import Foundation
import UserNotifications

/// Schedules a single daily local reminder. All on-device; no server, no
/// account. Errors are swallowed quietly — a reminder failing to schedule
/// should never break the app.
enum Reminders {
    static let id = "lumina.daily.reminder"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Schedule (or reschedule) the daily reminder at the given hour/minute.
    static func schedule(hour: Int, minute: Int, message: String) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Lumina"
        content.body = message
        content.sound = .default

        var comps = DateComponents()
        comps.hour = min(23, max(0, hour))
        comps.minute = min(59, max(0, minute))
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
