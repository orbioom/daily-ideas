import Foundation
import SwiftData
import UserNotifications

/// Thin, crash-proof wrapper over local notifications for bill reminders.
/// Authorization is requested gracefully; failures are swallowed so the app
/// never crashes if notifications are denied or unavailable.
enum Reminders {

    /// Requests authorization. The completion reports whether it's granted.
    static func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Reschedules reminders for every bill, `leadDays` before its next due date.
    /// Clears prior Remit reminders first. No-op if not authorized.
    static func reschedule(for bills: [Bill], leadDays: Int) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }

            center.removeAllPendingNotificationRequests()
            let cal = Calendar.current
            let now = Date()

            for bill in bills {
                guard let fireDate = cal.date(byAdding: .day, value: -max(0, leadDays), to: bill.dueDate),
                      fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "\(bill.name) is due soon"
                content.body = leadDays == 0
                    ? "Due today. Tap to mark it paid in Remit."
                    : "Due in \(leadDays) day\(leadDays == 1 ? "" : "s"). Stay ahead of the late fee."
                content.sound = .default

                let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "remit-\(bill.persistentModelID.hashValue)",
                    content: content,
                    trigger: trigger)
                center.add(request, withCompletionHandler: nil)
            }
        }
    }

    /// Removes all pending Remit reminders.
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
