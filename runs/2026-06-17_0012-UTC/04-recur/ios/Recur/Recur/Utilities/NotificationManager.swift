import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Schedules local reminders for upcoming renewals and ending trials.
/// Everything is gated behind the Settings toggle + Pro at the call site.
/// Permission denial is handled gracefully — nothing is force-unwrapped.
enum NotificationManager {

    /// Caps the number of pending notifications we schedule to stay polite.
    static let maxScheduled = 24

    /// Requests authorization. Calls back on the main queue with the outcome.
    static func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
        #else
        completion(false)
        #endif
    }

    /// Reports the current authorization status (granted / denied / notDetermined).
    static func authorizationStatus(_ completion: @escaping (Bool, Bool) -> Void) {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let granted = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            let determined = settings.authorizationStatus != .notDetermined
            DispatchQueue.main.async { completion(granted, determined) }
        }
        #else
        completion(false, true)
        #endif
    }

    /// Clears any previously scheduled Recur notifications.
    static func cancelAll() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #endif
    }

    /// Rebuilds the full notification schedule from the current data set.
    /// Renewal reminders fire `renewalLead` days before each renewal; trial
    /// reminders fire `trialLead` days before each trial end.
    static func reschedule(subscriptions: [Subscription],
                           renewalLead: Int,
                           trialLead: Int,
                           calendar: Calendar = .current) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let engine = RenewalEngine(calendar: calendar)
        let now = Date()
        var requests: [UNNotificationRequest] = []

        // Trial reminders first — they are time-critical.
        for sub in subscriptions where sub.isActive && sub.isTrial {
            guard let end = sub.trialEndDate else { continue }
            guard let fireDate = calendar.date(byAdding: .day, value: -max(0, trialLead), to: end),
                  fireDate > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Free trial ending soon"
            content.body = "\(sub.name) trial ends \(DateText.medium(end)). Cancel now if you don't want to be charged."
            content.sound = .default
            if let req = makeRequest(id: "trial-\(sub.id.uuidString)", fireDate: fireDate,
                                     content: content, calendar: calendar) {
                requests.append(req)
            }
        }

        // Renewal reminders.
        for sub in subscriptions where sub.isActive && !sub.isTrial {
            let next = engine.nextRenewal(firstBillingDate: sub.firstBillingDate, cycle: sub.cycle, reference: now)
            guard let fireDate = calendar.date(byAdding: .day, value: -max(0, renewalLead), to: next),
                  fireDate > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Upcoming renewal"
            let amount = MoneyFormatter.string(sub.costDecimal, code: sub.currencyCode)
            content.body = "\(sub.name) renews \(DateText.medium(next)) for \(amount)."
            content.sound = .default
            if let req = makeRequest(id: "renew-\(sub.id.uuidString)", fireDate: fireDate,
                                     content: content, calendar: calendar) {
                requests.append(req)
            }
        }

        // Cap and submit.
        for req in requests.prefix(maxScheduled) {
            center.add(req, withCompletionHandler: nil)
        }
        #endif
    }

    #if canImport(UserNotifications)
    private static func makeRequest(id: String, fireDate: Date,
                                    content: UNMutableNotificationContent,
                                    calendar: Calendar) -> UNNotificationRequest? {
        var comps = calendar.dateComponents([.year, .month, .day], from: fireDate)
        comps.hour = 9   // fire mid-morning
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
    #endif
}
