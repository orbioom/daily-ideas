import Foundation
import UserNotifications

/// Schedules an optional daily local notification reminding the learner to
/// review. Authorization is requested gracefully and every call is no-throw.
enum ReminderManager {
    private static let identifier = "verbatim.daily.review"

    /// Request authorization, then (re)schedule a daily reminder at `time`.
    /// If authorization is denied the toggle simply has no effect — never crashes.
    static func schedule(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let comps = Calendar.current.dateComponents([.hour, .minute], from: time)

            let content = UNMutableNotificationContent()
            content.title = "Time to review"
            content.body = "A few minutes today keeps your passages word-for-word."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: trigger)
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.add(request)
        }
    }

    /// Cancel the daily reminder.
    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
