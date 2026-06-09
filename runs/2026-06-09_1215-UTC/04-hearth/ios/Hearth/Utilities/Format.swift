import Foundation

/// Small, dependency-free formatting helpers shared across views.
enum Format {

    /// Human duration like "25 min" or "1 h 5 min".
    static func duration(minutes: Int) -> String {
        let m = max(0, minutes)
        if m < 60 { return "\(m) min" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h) h" : "\(h) h \(rem) min"
    }

    /// A short "every N" cadence label, e.g. "Daily", "Weekly", "Every 3 days".
    static func cadence(days: Int) -> String {
        let d = max(1, days)
        switch d {
        case 1: return "Daily"
        case 7: return "Weekly"
        case 14: return "Every 2 weeks"
        case 30, 31: return "Monthly"
        default:
            if d % 7 == 0 { return "Every \(d / 7) weeks" }
            return "Every \(d) days"
        }
    }

    /// Relative due phrasing from a signed day count (negative = overdue).
    static func duePhrase(daysFromNow days: Int) -> String {
        if days < 0 {
            let n = -days
            return n == 1 ? "1 day overdue" : "\(n) days overdue"
        }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \(days) days"
    }

    /// "Never" or a relative last-done label.
    static func lastDonePhrase(_ date: Date?, now: Date = .now, calendar: Calendar = .current) -> String {
        guard let date else { return "Never done" }
        if calendar.isDateInToday(date) { return "Done today" }
        if calendar.isDateInYesterday(date) { return "Done yesterday" }
        let days = HearthEngine.daysBetween(date, now, calendar: calendar)
        if days < 7 { return "Done \(days) days ago" }
        return "Done \(shortDay.string(from: date))"
    }

    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    /// A 0…1 fraction as a whole-number percent, e.g. "82%".
    static func percent(_ fraction: Double) -> String {
        "\(Int((min(1, max(0, fraction)) * 100).rounded()))%"
    }
}
