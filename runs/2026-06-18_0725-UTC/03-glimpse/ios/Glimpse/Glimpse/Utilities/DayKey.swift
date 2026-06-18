import Foundation

/// Helpers for the canonical `yyyy-MM-dd` day key used to group moments by day.
enum DayKey {
    /// A calendar fixed to the user's current calendar but with a stable formatter.
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        formatter.date(from: key)
    }

    static var today: String { key(for: Date()) }

    /// Number of days between two day keys (b - a), or nil if either is malformed.
    static func dayDistance(from a: String, to b: String) -> Int? {
        guard let da = date(from: a), let db = date(from: b) else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.day], from: cal.startOfDay(for: da), to: cal.startOfDay(for: db))
        return comps.day
    }
}
