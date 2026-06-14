import Foundation

/// Centralized, cached date formatters (creating `DateFormatter` is expensive).
enum DateFmt {
    /// e.g. "Sat, Jun 14, 2026"
    static let full: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, yyyy"
        return f
    }()

    /// e.g. "Jun 14"
    static let short: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    /// e.g. "Jun 14, 2026"
    static let medium: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    /// e.g. "3:45 PM"
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    /// e.g. "June 2026" — for calendar month headers.
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static let monthSymbols: [String] = {
        let f = DateFormatter()
        return f.standaloneMonthSymbols ?? []
    }()

    static func monthName(_ month: Int) -> String {
        guard month >= 1, month <= monthSymbols.count else { return "" }
        return monthSymbols[month - 1]
    }

    /// A friendly date+time line for an event, respecting its `includeTime` flag.
    static func line(for event: CountdownEvent, date: Date) -> String {
        if event.includeTime {
            return medium.string(from: date) + " · " + time.string(from: date)
        }
        return medium.string(from: date)
    }
}
