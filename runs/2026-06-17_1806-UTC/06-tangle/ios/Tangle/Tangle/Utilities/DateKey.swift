import Foundation

/// Stable yyyy-MM-dd keys and streak math for the daily puzzle.
enum DateKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date = .now) -> String {
        formatter.string(from: date)
    }

    /// Deterministic integer index for a date, used to pick the day's base word.
    static func dayNumber(for date: Date = .now) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        // A simple, stable ordinal that increases by 1 each calendar day.
        return y * 372 + m * 31 + d
    }

    /// Returns true if `a` and `b` are consecutive calendar days (b is the day after a).
    static func isNextDay(_ a: String, _ b: String) -> Bool {
        guard let da = formatter.date(from: a), let db = formatter.date(from: b) else { return false }
        let cal = Calendar(identifier: .gregorian)
        guard let next = cal.date(byAdding: .day, value: 1, to: da) else { return false }
        return cal.isDate(next, inSameDayAs: db)
    }
}
