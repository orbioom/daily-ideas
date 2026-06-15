import Foundation

/// Day-level date helpers used across the engine. All computations use the
/// user's current calendar and are tolerant of nil / edge inputs.
enum DateUtils {
    static var calendar: Calendar { Calendar.current }

    /// Start of day for a given date (defaults to now).
    static func startOfDay(_ date: Date = Date()) -> Date {
        calendar.startOfDay(for: date)
    }

    /// True when two dates fall on the same calendar day.
    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    /// Whole calendar days between two dates (b - a), clamped to >= 0.
    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        let start = calendar.startOfDay(for: a)
        let end = calendar.startOfDay(for: b)
        let comps = calendar.dateComponents([.day], from: start, to: end)
        return max(0, comps.day ?? 0)
    }

    /// Date offset by `days` from a base date (base defaults to now).
    static func adding(days: Int, to date: Date = Date()) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// 1...7 weekday index (Sunday = 1) for a date.
    static func weekday(_ date: Date = Date()) -> Int {
        calendar.component(.weekday, from: date)
    }

    /// Short weekday symbol, e.g. "Mon".
    static func shortWeekdaySymbol(forWeekday weekday: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols // index 0 == Sunday
        let idx = weekday - 1
        guard symbols.indices.contains(idx) else { return "" }
        return symbols[idx]
    }

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let weekdayShortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
}
