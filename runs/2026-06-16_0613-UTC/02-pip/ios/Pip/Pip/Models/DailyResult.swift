import Foundation
import SwiftData

/// A recorded Daily challenge result. One per calendar day (keyed by `dayKey`).
@Model
final class DailyResult {
    /// "YYYY-MM-DD" key — unique per day for the player.
    var dayKey: String
    var date: Date
    var score: Int
    var yahtzees: Int

    init(dayKey: String, date: Date, score: Int, yahtzees: Int) {
        self.dayKey = dayKey
        self.date = date
        self.score = score
        self.yahtzees = yahtzees
    }
}
