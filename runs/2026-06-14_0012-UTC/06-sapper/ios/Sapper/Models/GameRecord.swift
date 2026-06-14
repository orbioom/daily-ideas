import Foundation
import SwiftData

/// A completed game's outcome, kept for stats and history.
@Model
final class GameRecord {
    var id: UUID
    var date: Date
    var difficultyRaw: String
    var rows: Int
    var cols: Int
    var mines: Int
    var won: Bool
    var durationSec: Double
    var noGuess: Bool

    init(id: UUID = UUID(),
         date: Date = .now,
         difficultyRaw: String,
         rows: Int,
         cols: Int,
         mines: Int,
         won: Bool,
         durationSec: Double,
         noGuess: Bool) {
        self.id = id
        self.date = date
        self.difficultyRaw = difficultyRaw
        self.rows = rows
        self.cols = cols
        self.mines = mines
        self.won = won
        self.durationSec = durationSec
        self.noGuess = noGuess
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .custom
    }
}
