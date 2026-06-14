import Foundation

/// Shared, locale-stable formatting helpers.
enum Formatters {

    /// Calendar fixed to the user's current calendar but used for day-key math.
    static let calendar = Calendar.current

    /// "yyyy-MM-dd" key for a date, used to seed and look up daily challenges.
    static func dayKey(for date: Date = .now) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Parse a "yyyy-MM-dd" key back into a Date (start of that day) if valid.
    static func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else { return nil }
        var comps = DateComponents()
        comps.year = y
        comps.month = m
        comps.day = d
        return calendar.date(from: comps)
    }

    /// "M:SS" or "MM:SS" timer display from seconds.
    static func clock(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Short weekday symbol for a date (e.g. "Mon").
    static func shortWeekday(_ date: Date) -> String {
        let idx = calendar.component(.weekday, from: date) - 1
        let symbols = calendar.shortWeekdaySymbols
        guard idx >= 0 && idx < symbols.count else { return "" }
        return symbols[idx]
    }
}
