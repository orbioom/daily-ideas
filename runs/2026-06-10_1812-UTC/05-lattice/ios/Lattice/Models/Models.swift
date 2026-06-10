import Foundation
import SwiftData
import SwiftUI

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"

    var id: String { rawValue }

    /// Target number of given clues. Fewer clues → harder.
    var clueTarget: Int {
        switch self {
        case .easy: return 44
        case .medium: return 34
        case .hard: return 29
        case .expert: return 25
        }
    }

    var tint: Color {
        switch self {
        case .easy: return Brand.dynamic(0x4FA07C, 0x86C79A)
        case .medium: return Brand.dynamic(0x5E86B0, 0x8FBEE8)
        case .hard: return Brand.dynamic(0xC0913E, 0xE0B86A)
        case .expert: return Brand.dynamic(0xB1604E, 0xE08A78)
        }
    }
    var icon: String {
        switch self {
        case .easy: return "leaf.fill"
        case .medium: return "square.grid.2x2.fill"
        case .hard: return "flame.fill"
        case .expert: return "bolt.fill"
        }
    }
}

/// A saved game. The board is stored as three 81-length arrays plus a notes
/// array (each entry a bitmask of pencilled candidates). Survives relaunch.
@Model
final class SavedGame {
    var id: UUID
    var difficultyRaw: String
    var givens: [Int]       // 0 = empty
    var solution: [Int]
    var current: [Int]
    var notes: [Int]        // bitmask per cell: bit (d-1) set => candidate d
    var elapsed: Int        // seconds
    var mistakes: Int
    var hintsUsed: Int
    var isComplete: Bool
    var isDaily: Bool
    var dailyKey: Int       // yyyymmdd for daily games, else 0
    var createdAt: Date
    var updatedAt: Date

    init(difficulty: Difficulty, givens: [Int], solution: [Int], isDaily: Bool = false, dailyKey: Int = 0) {
        self.id = UUID()
        self.difficultyRaw = difficulty.rawValue
        self.givens = givens
        self.solution = solution
        self.current = givens
        self.notes = Array(repeating: 0, count: 81)
        self.elapsed = 0
        self.mistakes = 0
        self.hintsUsed = 0
        self.isComplete = false
        self.isDaily = isDaily
        self.dailyKey = dailyKey
        self.createdAt = .now
        self.updatedAt = .now
    }

    var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .easy }

    var filledCount: Int { current.filter { $0 != 0 }.count }
    var progress: Double { Double(filledCount) / 81.0 }
    func isGiven(_ index: Int) -> Bool { index >= 0 && index < 81 && givens[index] != 0 }
}

/// Aggregated performance per difficulty.
@Model
final class GameStats {
    @Attribute(.unique) var difficultyRaw: String
    var played: Int
    var won: Int
    var bestTime: Int       // seconds; 0 = none
    var totalWinTime: Int   // for average

    init(difficulty: Difficulty) {
        self.difficultyRaw = difficulty.rawValue
        self.played = 0
        self.won = 0
        self.bestTime = 0
        self.totalWinTime = 0
    }

    var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .easy }
    var winRate: Double { played == 0 ? 0 : Double(won) / Double(played) }
    var averageTime: Int { won == 0 ? 0 : totalWinTime / won }
}

/// A completed daily challenge, one per calendar day.
@Model
final class DailyResult {
    @Attribute(.unique) var dayKey: Int
    var date: Date
    var completed: Bool
    var timeSeconds: Int

    init(dayKey: Int, date: Date) {
        self.dayKey = dayKey
        self.date = date
        self.completed = false
        self.timeSeconds = 0
    }
}
