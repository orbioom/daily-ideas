import Foundation
import SwiftData
import SwiftUI

/// The five training games, one per cognitive domain.
enum Game: String, CaseIterable, Identifiable, Codable {
    case math       // numeracy
    case focus      // attention (Stroop)
    case logic      // reasoning (sequences)
    case memory     // working memory (grid recall)
    case anagram    // language (unscramble)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .math: return "Quick Math"
        case .focus: return "Color Focus"
        case .logic: return "Next in Line"
        case .memory: return "Memory Grid"
        case .anagram: return "Word Scramble"
        }
    }

    var domain: String {
        switch self {
        case .math: return "Numeracy"
        case .focus: return "Attention"
        case .logic: return "Reasoning"
        case .memory: return "Memory"
        case .anagram: return "Language"
        }
    }

    var blurb: String {
        switch self {
        case .math: return "Solve arithmetic against the clock."
        case .focus: return "Match the ink color, not the word."
        case .logic: return "Find the next number in the pattern."
        case .memory: return "Remember which tiles lit up."
        case .anagram: return "Rebuild the scrambled word."
        }
    }

    var icon: String {
        switch self {
        case .math: return "plus.forwardslash.minus"
        case .focus: return "eye"
        case .logic: return "arrow.right.to.line"
        case .memory: return "square.grid.3x3.fill"
        case .anagram: return "textformat.abc"
        }
    }

    var tint: Color {
        switch self {
        case .math: return Brand.dynamic(0x4E6BA8, 0x8FAEE8)
        case .focus: return Brand.dynamic(0xC0556E, 0xE08AA0)
        case .logic: return Brand.dynamic(0x4F9FB9, 0x86C7D6)
        case .memory: return Brand.dynamic(0x9A5BB0, 0xC79AE0)
        case .anagram: return Brand.dynamic(0x4FB98C, 0x86C79A)
        }
    }

    var isChoiceGame: Bool {
        switch self { case .math, .focus, .logic: return true; default: return false }
    }
}

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy, medium, hard
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    /// Multiplier applied to the score, rewarding harder settings.
    var scoreMultiplier: Double {
        switch self { case .easy: 1.0; case .medium: 1.25; case .hard: 1.5 }
    }
}

/// One completed play of a single game. Persisted for stats and trends.
@Model
final class GameResult {
    var id: UUID
    var gameRaw: String
    var score: Int
    var accuracy: Double      // 0...1
    var correct: Int
    var attempted: Int
    var difficultyRaw: String
    var date: Date
    /// Non-nil when this play was part of a daily workout (groups results).
    var workoutID: UUID?

    init(id: UUID = UUID(),
         game: Game,
         score: Int,
         accuracy: Double,
         correct: Int,
         attempted: Int,
         difficulty: Difficulty,
         date: Date = .now,
         workoutID: UUID? = nil) {
        self.id = id
        self.gameRaw = game.rawValue
        self.score = score
        self.accuracy = accuracy
        self.correct = correct
        self.attempted = attempted
        self.difficultyRaw = difficulty.rawValue
        self.date = date
        self.workoutID = workoutID
    }

    var game: Game { Game(rawValue: gameRaw) ?? .math }
    var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .medium }
}

/// In-memory result returned by a player before persistence.
struct PlayResult {
    let game: Game
    let score: Int
    let correct: Int
    let attempted: Int
    var accuracy: Double { attempted > 0 ? Double(correct) / Double(attempted) : 0 }
}
