import Foundation
import UserNotifications

/// Schedules local notifications as a *backstop* for alarms. Reveille rings reliably while
/// open or backgrounded via the audio engine; the notification ensures you still get a banner
/// + system sound at the alarm time even if the app was suspended. This is the honest iOS
/// behavior — a third-party app cannot guarantee a custom ringing alarm when force-quit.
@MainActor
final class NotificationManager: ObservableObject {

    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    /// Refresh the cached authorization status.
    func refresh() async {
        let settings = await center.notificationSettings()
        authorization = settings.authorizationStatus
    }

    /// Ask for permission (alert + sound). Safe to call repeatedly; resolves to the granted
    /// boolean. Never throws to the caller.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refresh()
            return granted
        } catch {
            await refresh()
            return false
        }
    }

    /// Schedule (or reschedule) a backstop notification for one alarm at its next fire date.
    /// One-shot alarms get a single calendar trigger; repeating alarms get a repeating weekday
    /// trigger per selected day. Removes any prior requests for this alarm first.
    func scheduleBackstop(for alarm: Alarm) {
        cancelBackstop(for: alarm)
        guard alarm.isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ \(alarm.label)"
        content.body = "Open Reveille to finish your dismiss mission."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let h = min(23, max(0, alarm.hour))
        let m = min(59, max(0, alarm.minute))

        if alarm.repeatDays.isEmpty {
            // One-shot: next occurrence.
            guard let fire = AlarmScheduler.nextFireDate(for: alarm) else { return }
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: requestID(alarm.id, day: 0),
                                                content: content, trigger: trigger)
            center.add(request)
        } else {
            for day in alarm.repeatDays where (1...7).contains(day) {
                var comps = DateComponents()
                comps.weekday = day
                comps.hour = h
                comps.minute = m
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let request = UNNotificationRequest(identifier: requestID(alarm.id, day: day),
                                                    content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    /// Cancel all backstop notifications for an alarm.
    func cancelBackstop(for alarm: Alarm) {
        let ids = (0...7).map { requestID(alarm.id, day: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Reschedule backstops for a full set of alarms (called after edits / on launch).
    func resyncAll(_ alarms: [Alarm]) {
        center.removeAllPendingNotificationRequests()
        for alarm in alarms { scheduleBackstop(for: alarm) }
    }

    private func requestID(_ alarmID: UUID, day: Int) -> String {
        "reveille.alarm.\(alarmID.uuidString).\(day)"
    }
}
