import Foundation
import UserNotifications

/// Schedules calendar-repeat local reminders for each scheduled dose.
/// All on-device; no server, no account.
enum NotificationScheduler {
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

    /// Rebuild all pending reminders from the current medications.
    /// iOS allows up to 64 pending notifications, so we cap defensively.
    static func reschedule(meds: [Medication], enabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        var scheduled = 0
        let cap = 60
        for med in meds where med.isActive && med.schedule != .asNeeded {
            for minute in med.times {
                let weekdays = activeWeekdays(for: med)
                for wd in weekdays {
                    if scheduled >= cap { return }
                    let content = UNMutableNotificationContent()
                    content.title = "Time for \(med.name)"
                    let dose = "\(med.dosesPerTime) \(med.form.label.lowercased())"
                    content.body = med.strength.isEmpty ? "Take \(dose)." : "Take \(dose) · \(med.strength)."
                    content.sound = .default

                    var comps = DateComponents()
                    comps.hour = minute / 60
                    comps.minute = minute % 60
                    if let wd { comps.weekday = wd }   // nil = every day

                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    let req = UNNotificationRequest(
                        identifier: "\(med.id.uuidString)-\(minute)-\(wd ?? 0)",
                        content: content, trigger: trigger)
                    try? await center.add(req)
                    scheduled += 1
                }
            }
        }
    }

    /// Returns [nil] for everyday (one daily trigger) or specific Calendar weekdays.
    private static func activeWeekdays(for med: Medication) -> [Int?] {
        switch med.schedule {
        case .everyDay: return [nil]
        case .asNeeded: return []
        case .daysOfWeek:
            var out: [Int?] = []
            for bit in 0..<7 where (med.dayMask & (1 << bit)) != 0 {
                out.append(bit + 1)   // Calendar weekday 1…7
            }
            return out
        }
    }
}
