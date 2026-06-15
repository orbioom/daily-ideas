import Foundation

/// Day-granular date helpers used across logging, stats, and correlation. All math goes through
/// `Calendar` / `DateComponents` so it stays leap-safe and timezone-consistent.
enum DayMath {
    static let calendar = Calendar.current

    /// Midnight at the start of `date` in the current calendar.
    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Whole-day difference `b - a` (e.g. 1 means b is the day after a). Guards nil → 0.
    static func dayDelta(from a: Date, to b: Date) -> Int {
        let a0 = startOfDay(a), b0 = startOfDay(b)
        return calendar.dateComponents([.day], from: a0, to: b0).day ?? 0
    }

    /// A list of consecutive day-starts going back `count` days, oldest first, ending today.
    static func recentDays(_ count: Int, endingAt end: Date = Date()) -> [Date] {
        guard count > 0 else { return [] }
        let today = startOfDay(end)
        var days: [Date] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            if let d = calendar.date(byAdding: .day, value: -offset, to: today) {
                days.append(d)
            }
        }
        return days
    }

    /// True if the two dates fall on the same calendar day.
    static func sameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }
}

extension Date {
    /// A compact "Jun 15" style label.
    var shortDayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: self)
    }

    /// "Mon, Jun 15" style label for day-detail headers.
    var mediumDayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: self)
    }
}
