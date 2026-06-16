import Foundation
import SwiftData

/// One record per puzzle the player has attempted (and, once won, completed).
/// `puzzleID` is the stable id from `PuzzleBank`. Unique so each puzzle has one record.
@Model
final class PuzzleRecord {
    @Attribute(.unique) var puzzleID: String
    var bestTimeSeconds: Int
    var completedDate: Date?
    var mistakes: Int
    var completed: Bool

    init(puzzleID: String,
         bestTimeSeconds: Int = 0,
         completedDate: Date? = nil,
         mistakes: Int = 0,
         completed: Bool = false) {
        self.puzzleID = puzzleID
        self.bestTimeSeconds = bestTimeSeconds
        self.completedDate = completedDate
        self.mistakes = mistakes
        self.completed = completed
    }
}
