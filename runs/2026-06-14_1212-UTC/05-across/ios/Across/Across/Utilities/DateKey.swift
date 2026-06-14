import Foundation

/// Calendar-day helpers used for the daily puzzle and streak math. All keys are
/// yyyy-MM-dd in the user's current calendar, so "today" is local.
enum DateKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// yyyy-MM-dd for a given date (defaults to now).
    static func key(for date: Date = .now) -> String {
        formatter.string(from: date)
    }

    /// Parse a yyyy-MM-dd key back to the start of that day, if valid.
    static func date(from key: String) -> Date? {
        formatter.date(from: key)
    }

    /// Whole days from `epoch` (a fixed reference) to the given day. Used to map
    /// a date deterministically to a puzzle index. Returns a non-negative count
    /// for dates on/after the reference; clamps below.
    static func dayNumber(for date: Date = .now) -> Int {
        let cal = Calendar(identifier: .gregorian)
        // Reference: 2024-01-01.
        var comps = DateComponents()
        comps.year = 2024; comps.month = 1; comps.day = 1
        guard let epoch = cal.date(from: comps) else { return 0 }
        let startEpoch = cal.startOfDay(for: epoch)
        let startDay = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: startEpoch, to: startDay).day ?? 0
        return max(0, days)
    }

    /// The day key for `offset` days before/after the given date.
    static func key(offsetDays: Int, from date: Date = .now) -> String {
        let cal = Calendar(identifier: .gregorian)
        let shifted = cal.date(byAdding: .day, value: offsetDays, to: date) ?? date
        return key(for: shifted)
    }
}
