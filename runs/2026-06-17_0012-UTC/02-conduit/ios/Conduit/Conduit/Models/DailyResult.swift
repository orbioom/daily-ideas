import Foundation
import SwiftData

/// One record per completed daily puzzle, keyed by the day key (yyyy-MM-dd).
@Model
final class DailyResult {
    @Attribute(.unique) var dayKey: String
    var puzzleId: String
    var solved: Bool
    var seconds: Int
    var perfect: Bool
    var date: Date

    init(dayKey: String, puzzleId: String, solved: Bool, seconds: Int, perfect: Bool, date: Date = .now) {
        self.dayKey = dayKey
        self.puzzleId = puzzleId
        self.solved = solved
        self.seconds = seconds
        self.perfect = perfect
        self.date = date
    }
}
