import Foundation
import SwiftData

/// Persisted progress for a single puzzle, enabling resume-on-relaunch.
@Model
final class PuzzleProgress {
    /// Stable key: "pack|index|difficulty".
    @Attribute(.unique) var puzzleKey: String
    var packName: String
    var difficultyRaw: String
    var seed: Int
    var gridSize: Int
    var foundWords: [String]
    var isComplete: Bool
    var elapsedSec: Int
    var bestTimeSec: Int?
    var startedDate: Date
    var completedDate: Date?

    init(
        puzzleKey: String,
        packName: String,
        difficultyRaw: String,
        seed: Int,
        gridSize: Int,
        foundWords: [String] = [],
        isComplete: Bool = false,
        elapsedSec: Int = 0,
        bestTimeSec: Int? = nil,
        startedDate: Date = .now,
        completedDate: Date? = nil
    ) {
        self.puzzleKey = puzzleKey
        self.packName = packName
        self.difficultyRaw = difficultyRaw
        self.seed = seed
        self.gridSize = gridSize
        self.foundWords = foundWords
        self.isComplete = isComplete
        self.elapsedSec = elapsedSec
        self.bestTimeSec = bestTimeSec
        self.startedDate = startedDate
        self.completedDate = completedDate
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .easy
    }
}
