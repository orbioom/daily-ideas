import SwiftData
import Foundation

enum GameType: String, Codable, CaseIterable {
    case memoryGrid     = "Memory"
    case quickMath      = "Math"
    case wordFlash      = "Words"
    case patternGame    = "Pattern"
    case reactionGame   = "Reaction"

    var icon: String {
        switch self {
        case .memoryGrid: return "brain.head.profile"
        case .quickMath:  return "plus.forwardslash.minus"
        case .wordFlash:  return "text.word.spacing"
        case .patternGame:return "circle.grid.2x2"
        case .reactionGame:return "bolt.fill"
        }
    }

    var color: String {
        switch self {
        case .memoryGrid: return "GameBlue"
        case .quickMath:  return "GameOrange"
        case .wordFlash:  return "GameGreen"
        case .patternGame:return "GamePink"
        case .reactionGame:return "GameYellow"
        }
    }

    var description: String {
        switch self {
        case .memoryGrid: return "Remember the highlighted cells"
        case .quickMath:  return "Solve arithmetic quickly"
        case .wordFlash:  return "Answer questions about flashed words"
        case .patternGame:return "Repeat the color sequence"
        case .reactionGame:return "Tap fast — avoid red!"
        }
    }
}

@Model
class GameSession {
    var gameTypeRaw: String
    var date: Date
    var score: Int          // 0-100
    var durationSeconds: Double
    var level: Int          // 1-10 adaptive

    var gameType: GameType { GameType(rawValue: gameTypeRaw) ?? .memoryGrid }

    init(gameType: GameType, score: Int, duration: Double, level: Int) {
        self.gameTypeRaw = gameType.rawValue
        self.date = Date()
        self.score = score
        self.durationSeconds = duration
        self.level = level
    }
}

@Model
class DailyResult {
    var date: Date          // normalized to midnight
    var totalScore: Int     // sum of all game scores (max 500)
    var gamesPlayed: Int    // 0-5
    var sessionIds: [String] // persisted UUIDs of sessions

    var percentComplete: Double { Double(gamesPlayed) / 5.0 }
    var averageScore: Int { gamesPlayed > 0 ? totalScore / gamesPlayed : 0 }

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalScore = 0
        self.gamesPlayed = 0
        self.sessionIds = []
    }
}
