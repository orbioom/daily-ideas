import Foundation
import SwiftData

/// One record per calendar day the player engaged with the Daily puzzle. Drives the
/// streak counter and the recent-days archive. `dateKey` is "yyyy-MM-dd" and unique.
@Model
final class DailyResult {
    @Attribute(.unique) var dateKey: String
    var puzzleID: String
    var completed: Bool
    var timeSeconds: Int
    var mistakes: Int

    init(dateKey: String,
         puzzleID: String,
         completed: Bool = false,
         timeSeconds: Int = 0,
         mistakes: Int = 0) {
        self.dateKey = dateKey
        self.puzzleID = puzzleID
        self.completed = completed
        self.timeSeconds = timeSeconds
        self.mistakes = mistakes
    }
}

/// Stable "yyyy-MM-dd" key for a date in the current calendar (UTC-stable formatting).
enum DateKey {
    static func string(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
