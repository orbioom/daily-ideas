import Foundation
import SwiftData

/// A recorded attempt at a puzzle, for stats and streaks.
@Model
final class PuzzleResult {
    var puzzleID: Int
    var date: Date
    var solved: Bool
    var hintsUsed: Int
    var attempts: Int

    init(puzzleID: Int,
         date: Date = Date(),
         solved: Bool = false,
         hintsUsed: Int = 0,
         attempts: Int = 1) {
        self.puzzleID = puzzleID
        self.date = date
        self.solved = solved
        self.hintsUsed = hintsUsed
        self.attempts = attempts
    }
}
