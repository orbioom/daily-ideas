import Foundation
import UserNotifications

/// Optional local expiry reminders. The app is fully functional with notifications
/// denied — every entry point is guarded and failures are swallowed quietly. We never
/// touch the network and never block the UI on permission.
enum NotificationManager {

    private static let categoryPrefix = "larder.expiry."

    /// Requests authorization once. Calls back with the granted result on the main
    /// actor. Safe to call when already authorized or already denied.
    static func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async { completion(true) }
            case .denied:
                DispatchQueue.main.async { completion(false) }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async { completion(granted) }
                }
            @unknown default:
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    /// Reads the current authorization status (for UI hints in Settings).
    static func authorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    /// Clears all previously scheduled Larder expiry reminders.
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// A minimal item snapshot for scheduling, decoupled from SwiftData.
    struct Reminder {
        var id: UUID
        var name: String
        var expiry: Date
    }

    /// Reschedules reminders for items expiring within `windowDays`. No-op (and a clean
    /// cancel) when disabled or unauthorized. Fires at 9am on the day before expiry, or
    /// immediately-future if that moment has already passed today.
    static func reschedule(reminders: [Reminder], windowDays: Int, enabled: Bool,
                           calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        cancelAll()
        guard enabled else { return }

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional else { return }

            let now = Date()
            for reminder in reminders {
                let comps = calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                                    to: calendar.startOfDay(for: reminder.expiry))
                guard let days = comps.day, days >= 0, days <= max(0, windowDays) else { continue }

                // Trigger at 9am the day before (or on the day if already adjacent).
                let triggerDay = calendar.date(byAdding: .day, value: -1, to: reminder.expiry) ?? reminder.expiry
                var fire = calendar.dateComponents([.year, .month, .day], from: triggerDay)
                fire.hour = 9
                fire.minute = 0
                guard let fireDate = calendar.date(from: fire), fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Use it soon"
                content.body = "\(reminder.name) is approaching its date."
                content.sound = .default

                let interval = fireDate.timeIntervalSince(now)
                guard interval > 0 else { continue }
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                let request = UNNotificationRequest(
                    identifier: categoryPrefix + reminder.id.uuidString,
                    content: content,
                    trigger: trigger)
                center.add(request, withCompletionHandler: nil)
            }
        }
    }
}
