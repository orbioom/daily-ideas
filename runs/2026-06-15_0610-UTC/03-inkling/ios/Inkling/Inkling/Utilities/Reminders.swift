import Foundation
import UserNotifications

/// A single daily "time to log" local notification. All of this is best-effort and never throws to
/// the UI — if permission is denied the toggle simply stays informative.
enum Reminders {
    private static let identifier = "inkling.daily.reminder"

    /// Request permission and, if granted, (re)schedule the daily reminder at `minutes` from
    /// midnight. Returns whether it was scheduled.
    static func enable(minutesFromMidnight: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        schedule(minutesFromMidnight: minutesFromMidnight)
        return true
    }

    /// (Re)schedule without re-prompting — used when only the time changes.
    static func schedule(minutesFromMidnight: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to check in"
        content.body = "Log today's symptoms and factors in Inkling — a few taps keeps your trends honest."
        content.sound = .default

        var components = DateComponents()
        components.hour = max(0, min(23, minutesFromMidnight / 60))
        components.minute = max(0, min(59, minutesFromMidnight % 60))

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    static func disable() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
