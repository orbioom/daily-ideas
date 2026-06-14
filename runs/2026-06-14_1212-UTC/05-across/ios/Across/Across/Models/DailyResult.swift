import Foundation
import SwiftData

/// A finished daily puzzle, recorded for streak + stats. One row per calendar
/// day a daily puzzle is solved.
@Model
final class DailyResult {
    /// Calendar day key, yyyy-MM-dd (the day the daily was assigned).
    @Attribute(.unique) var dateKey: String
    var puzzleID: String
    var solved: Bool
    var elapsedSeconds: Int
    var usedCheck: Bool
    var usedReveal: Bool
    /// The puzzle's difficulty raw value, snapshotted for stats grouping.
    var difficultyRaw: String
    var recordedAt: Date

    init(dateKey: String,
         puzzleID: String,
         solved: Bool,
         elapsedSeconds: Int,
         usedCheck: Bool,
         usedReveal: Bool,
         difficultyRaw: String,
         recordedAt: Date = .now) {
        self.dateKey = dateKey
        self.puzzleID = puzzleID
        self.solved = solved
        self.elapsedSeconds = elapsedSeconds
        self.usedCheck = usedCheck
        self.usedReveal = usedReveal
        self.difficultyRaw = difficultyRaw
        self.recordedAt = recordedAt
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .medium
    }
}
