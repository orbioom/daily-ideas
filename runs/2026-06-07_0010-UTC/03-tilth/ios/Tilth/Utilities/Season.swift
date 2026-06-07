import Foundation

/// Reads the gardener's frost dates from persisted preferences and turns them
/// into concrete dates for a given year. Single source of truth for the planner.
enum Season {
    enum Keys {
        static let springMonth = "springFrostMonth"
        static let springDay = "springFrostDay"
        static let fallMonth = "fallFrostMonth"
        static let fallDay = "fallFrostDay"
        static let zone = "hardinessZone"
    }

    static var currentYear: Int { Calendar.current.component(.year, from: .now) }

    private static func intOr(_ key: String, _ fallback: Int) -> Int {
        let v = UserDefaults.standard.integer(forKey: key)
        return v == 0 ? fallback : v
    }

    static func springFrost(year: Int = currentYear) -> Date {
        FrostMath.date(month: intOr(Keys.springMonth, 5),
                       day: intOr(Keys.springDay, 10), year: year)
    }

    static func fallFrost(year: Int = currentYear) -> Date {
        FrostMath.date(month: intOr(Keys.fallMonth, 10),
                       day: intOr(Keys.fallDay, 10), year: year)
    }

    static var zone: String {
        UserDefaults.standard.string(forKey: Keys.zone) ?? "6b"
    }

    static var frostFreeDays: Int {
        FrostMath.daysBetween(springFrost(), fallFrost())
    }
}
