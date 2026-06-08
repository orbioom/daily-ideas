import Foundation

enum Format {

    // MARK: - Dates

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static let dayOfMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    static let weekdayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    /// "Mon, Jun 8"
    static let dayFull: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    // MARK: - Ordinal

    static func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: - Streaks

    static func streakText(_ count: Int) -> String {
        switch count {
        case 0:  return "No streak yet"
        case 1:  return "1 day"
        default: return "\(count) days"
        }
    }

    static func weeksStreakText(_ count: Int) -> String {
        switch count {
        case 0:  return "No streak yet"
        case 1:  return "1 week"
        default: return "\(count) weeks"
        }
    }

    // MARK: - Percent

    static func percent(_ value: Double) -> String {
        let clamped = min(max(value, 0), 1)
        return "\(Int(clamped * 100))%"
    }

    // MARK: - Unit label

    static func unitLabel(count: Int, unit: String) -> String {
        guard !unit.isEmpty else { return "\(count)" }
        return "\(count) \(unit)"
    }

    // MARK: - Relative day label

    static func relativeDay(_ date: Date, relativeTo today: Date, calendar: Calendar) -> String {
        let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                               to: calendar.startOfDay(for: today)).day ?? 0
        switch daysDiff {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        default: return shortDate.string(from: date)
        }
    }
}
