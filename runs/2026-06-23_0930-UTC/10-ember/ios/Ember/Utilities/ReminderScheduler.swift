import Foundation
import UserNotifications

/// Schedules / cancels the optional daily breathing reminder. All calls are safe
/// to make regardless of authorization status — failures are swallowed gracefully.
enum ReminderScheduler {
    static let identifier = "ember.daily.reminder"

    /// Requests permission then schedules (or cancels) based on the toggle.
    static func sync(enabled: Bool, minuteOfDay: Int) {
        let center = UNUserNotificationCenter.current()
        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            schedule(minuteOfDay: minuteOfDay)
        }
    }

    private static func schedule(minuteOfDay: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to breathe"
        content.body = "A few mindful breaths can reset your whole day."
        content.sound = .default

        var components = DateComponents()
        components.hour = (minuteOfDay / 60) % 24
        components.minute = minuteOfDay % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }
}
