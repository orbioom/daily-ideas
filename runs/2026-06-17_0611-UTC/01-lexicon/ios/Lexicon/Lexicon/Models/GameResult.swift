import Foundation
import SwiftData

/// A completed game's record. Drives the Stats screen.
@Model
final class GameResult {
    @Attribute(.unique) var id: UUID
    /// The puzzle's calendar date (start of day) for daily/archive, or the moment
    /// of completion for practice. Used to bucket and sort.
    var date: Date
    /// The answer word, lowercased.
    var word: String
    /// GameMode rawValue ("daily" / "archive" / "practice").
    var mode: String
    var wordLength: Int
    /// Number of guesses used (1...maxGuesses). For a loss this equals maxGuesses.
    var guessCount: Int
    var won: Bool
    var completedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        word: String,
        mode: GameMode,
        wordLength: Int,
        guessCount: Int,
        won: Bool,
        completedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.word = word
        self.mode = mode.rawValue
        self.wordLength = wordLength
        self.guessCount = guessCount
        self.won = won
        self.completedAt = completedAt
    }

    /// The mode for this record (defaults to practice if data is malformed).
    var gameMode: GameMode { GameMode(rawValue: mode) ?? .practice }
}
