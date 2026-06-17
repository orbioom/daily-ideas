import Foundation
import UserNotifications

/// Optional, capped local reminders for due tasks. Never crashes if denied.
enum NotificationManager {

    /// Hard cap on scheduled notifications to stay well under the system limit.
    static let maxScheduled = 16

    /// Request authorization; the completion reports whether it was granted.
    static func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Cancel everything we previously scheduled.
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Schedule reminders for the soonest upcoming tasks, capped at `maxScheduled`.
    /// Only schedules for future due dates. Safe to call when authorization is unknown;
    /// the system simply drops requests if not authorized.
    static func reschedule(tasks: [MaintenanceTask],
                           hemisphere: Hemisphere,
                           calendar: Calendar = .current,
                           now: Date = Date()) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Compute upcoming due dates for active tasks.
        struct Upcoming { let task: MaintenanceTask; let due: Date }
        var upcoming: [Upcoming] = []
        for task in tasks where task.isActive {
            if let due = ScheduleEngine.nextDue(for: task, hemisphere: hemisphere, now: now, calendar: calendar),
               due > now {
                upcoming.append(Upcoming(task: task, due: due))
            }
        }
        let soonest = upcoming.sorted { $0.due < $1.due }.prefix(maxScheduled)

        for item in soonest {
            let content = UNMutableNotificationContent()
            content.title = "Upkeep due"
            content.body = "\(item.task.title) is due."
            content.sound = .default

            // Fire at 9am on the due day.
            var comps = calendar.dateComponents([.year, .month, .day], from: item.due)
            comps.hour = 9
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: "upkeep-\(item.task.id.uuidString)",
                                                content: content,
                                                trigger: trigger)
            center.add(request) { _ in }
        }
    }
}
