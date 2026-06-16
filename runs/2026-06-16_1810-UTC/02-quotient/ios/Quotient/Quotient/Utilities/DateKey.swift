import Foundation

/// Helpers for the "YYYY-MM-DD" date keys used to seed and index daily puzzles.
enum DateKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        formatter.date(from: key)
    }

    static var today: String { key(for: Date()) }

    /// All date keys for the days leading up to (and including) `date`.
    static func recentKeys(endingAt date: Date = Date(), count: Int) -> [String] {
        guard count > 0 else { return [] }
        let cal = Calendar(identifier: .gregorian)
        var keys: [String] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            if let day = cal.date(byAdding: .day, value: -offset, to: date) {
                keys.append(key(for: day))
            }
        }
        return keys
    }
}
