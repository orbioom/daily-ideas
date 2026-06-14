import Foundation
import SwiftData

/// Saved progress for one puzzle. Lets a solver resume exactly where they left
/// off — including which cells they've revealed/checked.
///
/// `enteredLetters`, `revealedMask`, and `checkedMask` are all row-major strings
/// of the SAME length as the grid (rows * cols). For `enteredLetters`:
/// `'.'` = empty, `'#'` = block, otherwise an uppercase letter. For the masks:
/// `'1'` = set, `'0'` = unset, `'#'` = block.
@Model
final class PuzzleProgress {
    @Attribute(.unique) var puzzleID: String
    /// Row-major entered letters ('.'=empty, '#'=block, else A–Z).
    var enteredLetters: String
    /// Row-major revealed flags ('1' revealed, '0' not, '#' block).
    var revealedMask: String
    /// Row-major checked flags ('1' checked, '0' not, '#' block).
    var checkedMask: String
    var completed: Bool
    var elapsedSeconds: Int
    var solvedAt: Date?
    var lastPlayedAt: Date

    init(puzzleID: String,
         enteredLetters: String,
         revealedMask: String,
         checkedMask: String,
         completed: Bool = false,
         elapsedSeconds: Int = 0,
         solvedAt: Date? = nil,
         lastPlayedAt: Date = .now) {
        self.puzzleID = puzzleID
        self.enteredLetters = enteredLetters
        self.revealedMask = revealedMask
        self.checkedMask = checkedMask
        self.completed = completed
        self.elapsedSeconds = elapsedSeconds
        self.solvedAt = solvedAt
        self.lastPlayedAt = lastPlayedAt
    }
}
