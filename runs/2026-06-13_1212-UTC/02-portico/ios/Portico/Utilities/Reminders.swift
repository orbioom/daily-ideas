import Foundation
import UserNotifications

/// Schedules the optional morning and evening reflection reminders. Requests
/// authorization gracefully and never crashes if permission is denied.
enum Reminders {
    static let morningID = "portico.reminder.morning"
    static let eveningID = "portico.reminder.evening"

    /// Requests notification authorization. The completion reports whether the
    /// app may post notifications, on the main queue.
    static func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Re-applies all reminders from the current preferences. Safe to call any
    /// time; clears any reminder whose toggle is off.
    static func sync(morningOn: Bool, morningHour: Int, morningMinute: Int,
                     eveningOn: Bool, eveningHour: Int, eveningMinute: Int) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let allowed = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            guard allowed else {
                center.removePendingNotificationRequests(withIdentifiers: [morningID, eveningID])
                return
            }
            apply(on: morningOn, id: morningID, hour: morningHour, minute: morningMinute,
                  title: "Morning preparation",
                  body: "Set your intention before the day begins.")
            apply(on: eveningOn, id: eveningID, hour: eveningHour, minute: eveningMinute,
                  title: "Evening reflection",
                  body: "How did you meet the day? Take a quiet moment.")
        }
    }

    private static func apply(on: Bool, id: String, hour: Int, minute: Int,
                              title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard on else { return }

        var comps = DateComponents()
        comps.hour = min(max(0, hour), 23)
        comps.minute = min(max(0, minute), 59)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }
}
