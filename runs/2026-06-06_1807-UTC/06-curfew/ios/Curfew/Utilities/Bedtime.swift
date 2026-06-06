import Foundation

/// Resolves the user's bedtime preference into concrete dates.
enum Bedtime {
    /// The next upcoming bedtime at or after `now`.
    static func next(hour: Int, minute: Int, from now: Date = .now) -> Date {
        let cal = Calendar.current
        let today = cal.date(bySettingHour: min(23, max(0, hour)), minute: min(59, max(0, minute)),
                             second: 0, of: now) ?? now
        return today > now ? today : (cal.date(byAdding: .day, value: 1, to: today) ?? today)
    }
}
