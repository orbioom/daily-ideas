import Foundation
import SwiftData

/// The single in-progress puzzle, resumed on relaunch. The grid is stored as a compact
/// string via `GridCodec`; decode failures fall back to a fresh board rather than crashing.
/// Unique on `puzzleID` so there is exactly one saved game per puzzle.
@Model
final class SavedGame {
    @Attribute(.unique) var puzzleID: String
    /// Encoded cell-state grid (see `GridCodec`).
    var gridState: String
    var elapsedSeconds: Int
    var mistakes: Int
    var updatedAt: Date

    init(puzzleID: String,
         gridState: String,
         elapsedSeconds: Int = 0,
         mistakes: Int = 0,
         updatedAt: Date = Date()) {
        self.puzzleID = puzzleID
        self.gridState = gridState
        self.elapsedSeconds = elapsedSeconds
        self.mistakes = mistakes
        self.updatedAt = updatedAt
    }
}
