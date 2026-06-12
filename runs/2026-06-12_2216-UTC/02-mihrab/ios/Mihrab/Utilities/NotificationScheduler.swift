import Foundation
import UserNotifications

/// Schedules local notifications for upcoming prayers (next 2 days, the five
/// obligatory prayers only — at most 10 pending requests, well under the 64 cap).
/// Rescheduled whenever the app foregrounds or settings change.
enum NotificationScheduler {
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound])
        return granted ?? false
    }

    static func reschedule(enabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }

        let settings = PrayerSettings.current()
        let formatter = settings.timeFormatter()
        let now = Date.now

        for dayOffset in 0...1 {
            guard let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let times = settings.times(on: day)
            for prayer in Prayer.obligatory {
                guard let fireDate = times.time(for: prayer), fireDate > now else { continue }
                let content = UNMutableNotificationContent()
                content.title = "\(prayer.displayName) · \(prayer.arabicName)"
                content.body = "It is time for \(prayer.displayName) in \(settings.city.name) — \(formatter.string(from: fireDate))."
                content.sound = .default

                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = settings.city.timeZone
                var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                comps.timeZone = settings.city.timeZone
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "prayer-\(prayer.rawValue)-\(dayOffset)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }
}
