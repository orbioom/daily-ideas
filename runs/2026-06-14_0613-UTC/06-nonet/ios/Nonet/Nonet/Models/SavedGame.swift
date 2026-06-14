import Foundation
import SwiftData

/// The persisted in-progress (or completed) game. Stored via SwiftData so the player can
/// resume after relaunch. `[Int]` properties are fully supported by SwiftData.
///
/// `candidates` is a flattened bitmask per cell (bit d-1 set => digit d is pencilled in).
@Model
final class SavedGame {
    @Attribute(.unique) var id: UUID
    var givens: [Int]        // length 81
    var current: [Int]       // length 81, player's working grid
    var candidates: [Int]    // length 81, pencil-mark bitmasks
    var solution: [Int]      // length 81
    var difficultyRaw: Int
    var isDaily: Bool
    var dateKey: String      // "yyyyMMdd" for daily, "" otherwise
    var elapsedSec: Int
    var mistakes: Int
    var hintsUsed: Int
    var completed: Bool
    var isActive: Bool       // the currently-active slot to resume
    var createdAt: Date
    var lastPlayed: Date

    init(id: UUID = UUID(),
         givens: [Int],
         current: [Int],
         candidates: [Int],
         solution: [Int],
         difficulty: Difficulty,
         isDaily: Bool,
         dateKey: String,
         elapsedSec: Int = 0,
         mistakes: Int = 0,
         hintsUsed: Int = 0,
         completed: Bool = false,
         isActive: Bool = true,
         createdAt: Date = Date(),
         lastPlayed: Date = Date()) {
        self.id = id
        self.givens = givens
        self.current = current
        self.candidates = candidates
        self.solution = solution
        self.difficultyRaw = difficulty.rawValue
        self.isDaily = isDaily
        self.dateKey = dateKey
        self.elapsedSec = elapsedSec
        self.mistakes = mistakes
        self.hintsUsed = hintsUsed
        self.completed = completed
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastPlayed = lastPlayed
    }

    var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .easy }

    /// Filled-cell progress 0...1 (ignores givens denominator subtleties; simple & safe).
    var progress: Double {
        guard current.count == 81 else { return 0 }
        let filled = current.reduce(0) { $0 + ($1 != 0 ? 1 : 0) }
        return Double(filled) / 81.0
    }
}
