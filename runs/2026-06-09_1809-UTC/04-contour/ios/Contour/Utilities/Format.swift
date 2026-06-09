import Foundation

/// Small, dependency-free date/number formatting helpers shared across views.
enum Format {
    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let shortDayYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return shortDayYear.string(from: date)
    }

    /// "12 days", "1 day", "today".
    static func days(_ count: Int) -> String {
        let n = max(0, count)
        if n == 0 { return "today" }
        return n == 1 ? "1 day" : "\(n) days"
    }
}
