import Foundation

/// Stable yyyy-MM-dd keys (local calendar) used for the Daily puzzle and streak math.
enum DateKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        formatter.date(from: key)
    }

    static var today: String {
        key(for: Date())
    }

    /// Friendly display string, e.g. "Tue, Jun 18".
    static func display(_ key: String) -> String {
        guard let date = date(from: key) else { return key }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}
