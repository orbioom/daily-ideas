import Foundation
import SwiftData

/// A resumable in-progress (or completed) game. Persisted via SwiftData so the
/// player can quit mid-puzzle and resume exactly where they left off.
@Model
final class SavedGame {
    @Attribute(.unique) var id: UUID
    var puzzleData: Data        // encoded Puzzle
    var stateData: Data         // encoded [CellState]
    var size: Int
    var difficultyRaw: String
    var elapsedSeconds: Int
    var mistakes: Int
    var hintsUsed: Int
    var isDaily: Bool
    var dateKey: String         // for dailies; "" for free play
    var isCompleted: Bool
    var startedAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        puzzleData: Data,
        stateData: Data,
        size: Int,
        difficulty: Difficulty,
        elapsedSeconds: Int = 0,
        mistakes: Int = 0,
        hintsUsed: Int = 0,
        isDaily: Bool = false,
        dateKey: String = "",
        isCompleted: Bool = false,
        startedAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.puzzleData = puzzleData
        self.stateData = stateData
        self.size = size
        self.difficultyRaw = difficulty.rawValue
        self.elapsedSeconds = elapsedSeconds
        self.mistakes = mistakes
        self.hintsUsed = hintsUsed
        self.isDaily = isDaily
        self.dateKey = dateKey
        self.isCompleted = isCompleted
        self.startedAt = startedAt
        self.updatedAt = updatedAt
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .easy
    }

    /// Decodes the stored puzzle, returning nil on any corruption rather than crashing.
    func decodedPuzzle() -> Puzzle? {
        try? JSONDecoder().decode(Puzzle.self, from: puzzleData)
    }

    func decodedState() -> [CellState]? {
        try? JSONDecoder().decode([CellState].self, from: stateData)
    }
}
