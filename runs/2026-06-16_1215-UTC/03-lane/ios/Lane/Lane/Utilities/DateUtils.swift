import Foundation

/// Calendar/date helpers used across Agenda and Insights. All operations are
/// guarded — they never force-unwrap optional date math.
enum DateUtils {
    static let calendar = Calendar.current

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    static func isOverdue(_ date: Date, reference: Date = Date()) -> Bool {
        startOfDay(date) < startOfDay(reference)
    }

    /// True when the date is within the next `days` days (exclusive of overdue).
    static func isDueSoon(_ date: Date, within days: Int = 3, reference: Date = Date()) -> Bool {
        let start = startOfDay(reference)
        guard let limit = calendar.date(byAdding: .day, value: max(0, days), to: start) else { return false }
        let d = startOfDay(date)
        return d >= start && d <= limit
    }

    static func isThisWeek(_ date: Date, reference: Date = Date()) -> Bool {
        calendar.isDate(date, equalTo: reference, toGranularity: .weekOfYear)
    }

    /// Start of the ISO-style week (respecting the user's locale first weekday).
    static func startOfWeek(_ date: Date) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? startOfDay(date)
    }

    static func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func relativeLabel(for date: Date, reference: Date = Date()) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = calendar.isDate(date, equalTo: reference, toGranularity: .year) ? "EEE, MMM d" : "MMM d, yyyy"
        return f.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    static func weekdayShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
}
