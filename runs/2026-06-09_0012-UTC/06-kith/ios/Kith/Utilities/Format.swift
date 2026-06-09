import Foundation

enum Format {
    static let shortDate: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    static let monthDay: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()
    static let monthYear: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f
    }()

    static func relativeDay(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let diff = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: now)).day ?? 0
        switch diff {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...6: return "\(diff) days ago"
        default: return shortDate.string(from: date)
        }
    }

    static func sinceLabel(_ days: Int?) -> String {
        guard let days else { return "No contact yet" }
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...30: return "\(days) days ago"
        case 31...60: return "About a month ago"
        default: return "\(days / 30) months ago"
        }
    }
}
