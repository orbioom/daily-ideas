import Foundation
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter` for the optional daily reading
/// reminder. All work guards against denied authorization so the UI can fall
/// back gracefully without ever crashing.
enum ReminderManager {
    static let identifier = "margin.daily.reminder"

    /// Requests authorization, then schedules (or, if denied, reports false).
    static func enable(at components: DateComponents, completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                guard granted else { completion(false); return }
                schedule(at: components)
                completion(true)
            }
        }
    }

    /// Schedules the repeating daily reminder at the given hour/minute.
    static func schedule(at components: DateComponents) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to read"
        content.body = "A few pages today keeps your streak and your challenge alive."
        content.sound = .default

        var trigger = DateComponents()
        trigger.hour = components.hour ?? 20
        trigger.minute = components.minute ?? 0

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        center.add(request, withCompletionHandler: nil)
    }

    /// Cancels the scheduled reminder.
    static func disable() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Reports current authorization status on the main queue.
    static func checkAuthorization(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }
}
