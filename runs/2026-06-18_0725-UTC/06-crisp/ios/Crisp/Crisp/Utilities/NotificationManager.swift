import Foundation
import UserNotifications

/// Wraps local notification permission + scheduling for timer completion.
/// Politely requests permission only when the user first starts a timer.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    /// Cap on simultaneously pending timer notifications to stay well-behaved.
    static let pendingCap = 16

    /// Requests authorization if still undetermined. Returns whether we're allowed.
    @discardableResult
    func ensureAuthorized() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            return granted
        @unknown default:
            return false
        }
    }

    /// Schedules a one-shot notification that fires when the timer ends.
    func schedule(id: UUID, label: String, fireDate: Date, soundEnabled: Bool) async {
        let center = UNUserNotificationCenter.current()

        // Respect the pending cap.
        let pending = await center.pendingNotificationRequests()
        if pending.count >= Self.pendingCap { return }

        let interval = fireDate.timeIntervalSinceNow
        guard interval > 0.5 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Crisp"
        content.body = label.isEmpty ? "Your timer is done!" : "\(label) is done — golden and crisp!"
        content.sound = soundEnabled ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
        try? await center.add(request)
    }

    /// Cancels a pending timer notification (e.g. when paused or stopped).
    func cancel(id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
