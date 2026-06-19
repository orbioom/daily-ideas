import Foundation
import UserNotifications

@Observable
final class BreakScheduler {
    var permissionStatus: UNAuthorizationStatus = .notDetermined
    var nextBreakDate: Date?
    var countdown: Int = 0
    private var countdownTimer: Timer?

    init() {
        Task { await refreshStatus() }
    }

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            return granted
        } catch {
            return false
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            permissionStatus = settings.authorizationStatus
        }
    }

    func scheduleBreaks(schedule: UserSchedule) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard schedule.remindersEnabled else {
            stopCountdown()
            nextBreakDate = nil
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time for a break"
        content.body = "Quick posture check — you've earned it!"
        content.sound = .default

        let intervalSeconds = TimeInterval(schedule.intervalMinutes * 60)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: intervalSeconds,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "break.reminder",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)

        let next = Date().addingTimeInterval(intervalSeconds)
        nextBreakDate = next
        schedule.nextBreakDate = next
        startCountdown(to: next)
    }

    func cancelAllBreaks() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        stopCountdown()
        nextBreakDate = nil
    }

    private func startCountdown(to date: Date) {
        stopCountdown()
        updateCountdown(to: date)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown(to: date)
        }
    }

    private func updateCountdown(to date: Date) {
        let remaining = Int(date.timeIntervalSinceNow)
        countdown = max(0, remaining)
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    var countdownFormatted: String {
        let m = countdown / 60
        let s = countdown % 60
        return String(format: "%d:%02d", m, s)
    }

    var isPermissionGranted: Bool {
        permissionStatus == .authorized
    }
}
