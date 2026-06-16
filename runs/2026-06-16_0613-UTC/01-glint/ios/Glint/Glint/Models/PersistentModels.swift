import Foundation
import SwiftData

/// Progress for a single level (stars earned, best score, unlock state).
@Model
final class LevelProgress {
    @Attribute(.unique) var levelID: Int
    var stars: Int
    var bestScore: Int
    var unlocked: Bool
    var completed: Bool

    init(levelID: Int, stars: Int = 0, bestScore: Int = 0, unlocked: Bool = false, completed: Bool = false) {
        self.levelID = levelID
        self.stars = stars
        self.bestScore = bestScore
        self.unlocked = unlocked
        self.completed = completed
    }
}

/// Result of one Daily challenge attempt (one per day key).
@Model
final class DailyResult {
    @Attribute(.unique) var dayKey: String
    var date: Date
    var score: Int
    var moves: Int
    var won: Bool

    init(dayKey: String, date: Date, score: Int, moves: Int, won: Bool) {
        self.dayKey = dayKey
        self.date = date
        self.score = score
        self.moves = moves
        self.won = won
    }
}

/// A resumable saved game (Zen, or an in-progress level) stored as JSON board.
@Model
final class SavedGame {
    /// One save per mode slot ("zen", "level", "daily").
    @Attribute(.unique) var slot: String
    var modeRaw: String
    var levelID: Int?
    var score: Int
    var movesUsed: Int
    var boardData: Data
    var rngState: Data
    var updatedAt: Date

    init(slot: String, modeRaw: String, levelID: Int?, score: Int, movesUsed: Int, boardData: Data, rngState: Data, updatedAt: Date = Date()) {
        self.slot = slot
        self.modeRaw = modeRaw
        self.levelID = levelID
        self.score = score
        self.movesUsed = movesUsed
        self.boardData = boardData
        self.rngState = rngState
        self.updatedAt = updatedAt
    }
}

/// A finished game record, powering the Stats screen.
@Model
final class GameRecord {
    var date: Date
    var modeRaw: String
    var score: Int
    var levelID: Int?
    var stars: Int
    var bestCombo: Int
    var gemsCleared: Int

    init(date: Date, modeRaw: String, score: Int, levelID: Int? = nil, stars: Int = 0, bestCombo: Int = 0, gemsCleared: Int = 0) {
        self.date = date
        self.modeRaw = modeRaw
        self.score = score
        self.levelID = levelID
        self.stars = stars
        self.bestCombo = bestCombo
        self.gemsCleared = gemsCleared
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .zen }
}

/// Single-row holder for Zen high score (kept in SwiftData so it survives relaunch).
@Model
final class ZenScore {
    @Attribute(.unique) var key: String
    var highScore: Int

    init(key: String = "zen", highScore: Int = 0) {
        self.key = key
        self.highScore = highScore
    }
}
