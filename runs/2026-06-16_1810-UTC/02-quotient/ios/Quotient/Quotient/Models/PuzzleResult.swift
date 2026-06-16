import Foundation
import SwiftData

/// A finished game record used to compute statistics and streaks.
@Model
final class PuzzleResult {
    @Attribute(.unique) var id: UUID
    var size: Int
    var difficultyRaw: String
    var durationSeconds: Int
    var mistakes: Int
    var hintsUsed: Int
    var won: Bool
    var date: Date
    var isDaily: Bool
    var dateKey: String

    init(
        id: UUID = UUID(),
        size: Int,
        difficulty: Difficulty,
        durationSeconds: Int,
        mistakes: Int,
        hintsUsed: Int,
        won: Bool,
        date: Date = Date(),
        isDaily: Bool = false,
        dateKey: String = ""
    ) {
        self.id = id
        self.size = size
        self.difficultyRaw = difficulty.rawValue
        self.durationSeconds = durationSeconds
        self.mistakes = mistakes
        self.hintsUsed = hintsUsed
        self.won = won
        self.date = date
        self.isDaily = isDaily
        self.dateKey = dateKey
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .easy
    }
}
