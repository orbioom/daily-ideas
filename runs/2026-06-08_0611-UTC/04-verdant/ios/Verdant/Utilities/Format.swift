import Foundation

enum Format {

    // MARK: - Relative due text

    static func relativeDue(days: Int) -> String {
        switch days {
        case ..<0:
            let n = -days
            return n == 1 ? "1 day overdue" : "\(n) days overdue"
        case 0:
            return "Due today"
        case 1:
            return "In 1 day"
        default:
            return "In \(days) days"
        }
    }

    static func relativeDue(from date: Date, now: Date = Date()) -> String {
        let days = CareEngine.daysUntil(date, now: now)
        return relativeDue(days: days)
    }

    // MARK: - Short date

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func shortDate(_ date: Date) -> String {
        shortDate.string(from: date)
    }

    // MARK: - Month + year

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()

    static func monthYear(_ date: Date) -> String {
        monthYear.string(from: date)
    }

    // MARK: - Relative past

    static func relativePast(from date: Date, now: Date = Date()) -> String {
        let days = CareEngine.daysUntil(date, now: now) // negative = past
        let n = -days
        if n <= 0  { return "Today" }
        if n == 1  { return "Yesterday" }
        if n < 7   { return "\(n) days ago" }
        if n < 14  { return "1 week ago" }
        if n < 30  { return "\(n / 7) weeks ago" }
        return shortDate(date)
    }

    // MARK: - Interval label

    static func intervalLabel(days: Int) -> String {
        if days == 0 { return "Never" }
        if days == 1 { return "Every day" }
        if days == 7 { return "Every week" }
        if days == 14 { return "Every 2 weeks" }
        if days == 30 { return "Monthly" }
        return "Every \(days) days"
    }
}
