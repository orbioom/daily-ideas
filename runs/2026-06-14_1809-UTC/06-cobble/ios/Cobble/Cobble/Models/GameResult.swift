import Foundation
import SwiftData

/// A finished game's record. Drives the Stats screen and charts.
@Model
final class GameResult {
    @Attribute(.unique) var id: UUID
    var date: Date
    var score: Int
    var linesCleared: Int
    var piecesPlaced: Int
    var longestCombo: Int
    var modeRaw: String
    var durationSec: Int
    /// "yyyyMMdd" for daily entries (used for the daily streak/calendar), "" otherwise.
    var dateKey: String

    init(id: UUID = UUID(),
         date: Date = Date(),
         score: Int,
         linesCleared: Int,
         piecesPlaced: Int,
         longestCombo: Int = 0,
         mode: GameMode,
         durationSec: Int,
         dateKey: String = "") {
        self.id = id
        self.date = date
        self.score = max(0, score)
        self.linesCleared = max(0, linesCleared)
        self.piecesPlaced = max(0, piecesPlaced)
        self.longestCombo = max(0, longestCombo)
        self.modeRaw = mode.rawValue
        self.durationSec = max(0, durationSec)
        self.dateKey = dateKey
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .classic }
}
