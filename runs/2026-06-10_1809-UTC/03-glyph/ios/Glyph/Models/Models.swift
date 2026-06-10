import Foundation
import SwiftData
import SwiftUI

enum SudokuDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy, medium, hard, expert
    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    /// Approximate clue counts. Fewer clues → harder.
    var targetClues: Int {
        switch self {
        case .easy: return 40
        case .medium: return 33
        case .hard: return 28
        case .expert: return 24
        }
    }

    var tint: Color {
        switch self {
        case .easy: return Brand.dynamic(0x4FB98C, 0x86C79A)
        case .medium: return Brand.dynamic(0x4E6BA8, 0x8FAEE8)
        case .hard: return Brand.dynamic(0xC0793E, 0xE0A878)
        case .expert: return Brand.dynamic(0xC0556E, 0xE08AA0)
        }
    }
}

/// A persisted Sudoku game. Grids are stored as 81-character strings ('0' = empty)
/// so the whole game survives relaunch. Notes are stored as 81 comma-separated
/// candidate bitmasks.
@Model
final class SudokuGame {
    var id: UUID
    var difficultyRaw: String
    var givens: String       // 81 chars, immutable clues ('0' = blank)
    var solution: String     // 81 chars, the unique solution
    var entries: String      // 81 chars, the player's current values
    var notesEncoded: String // 81 comma-separated bitmasks
    var elapsedSeconds: Int
    var mistakes: Int
    var hintsUsed: Int
    var isComplete: Bool
    var isDaily: Bool
    var startedAt: Date
    var updatedAt: Date
    var finishedAt: Date?

    init(id: UUID = UUID(),
         difficulty: SudokuDifficulty,
         givens: [Int],
         solution: [Int],
         isDaily: Bool = false) {
        self.id = id
        self.difficultyRaw = difficulty.rawValue
        self.givens = SudokuGame.encode(givens)
        self.solution = SudokuGame.encode(solution)
        self.entries = SudokuGame.encode(givens)
        self.notesEncoded = Array(repeating: "0", count: 81).joined(separator: ",")
        self.elapsedSeconds = 0
        self.mistakes = 0
        self.hintsUsed = 0
        self.isComplete = false
        self.isDaily = isDaily
        self.startedAt = .now
        self.updatedAt = .now
        self.finishedAt = nil
    }

    var difficulty: SudokuDifficulty { SudokuDifficulty(rawValue: difficultyRaw) ?? .easy }

    // MARK: - Grid access

    var givenGrid: [Int] { SudokuGame.decode(givens) }
    var solutionGrid: [Int] { SudokuGame.decode(solution) }

    var entryGrid: [Int] {
        get { SudokuGame.decode(entries) }
        set { entries = SudokuGame.encode(newValue); updatedAt = .now }
    }

    /// Notes per cell as a Set of digits.
    var notes: [Set<Int>] {
        get { SudokuGame.decodeNotes(notesEncoded) }
        set { notesEncoded = SudokuGame.encodeNotes(newValue); updatedAt = .now }
    }

    var isGiven: [Bool] {
        givens.map { $0 != "0" }
    }

    var filledCount: Int { entryGrid.filter { $0 != 0 }.count }

    var progress: Double { Double(filledCount) / 81.0 }

    // MARK: - Encoding helpers

    static func encode(_ grid: [Int]) -> String {
        String(grid.map { Character("\($0)") })
    }

    static func decode(_ s: String) -> [Int] {
        let arr = s.compactMap { $0.wholeNumberValue }
        if arr.count == 81 { return arr }
        return Array(repeating: 0, count: 81)
    }

    static func encodeNotes(_ notes: [Set<Int>]) -> String {
        let safe = notes.count == 81 ? notes : Array(repeating: Set<Int>(), count: 81)
        return safe.map { set in
            var mask = 0
            for d in set where (1...9).contains(d) { mask |= (1 << (d - 1)) }
            return String(mask)
        }.joined(separator: ",")
    }

    static func decodeNotes(_ s: String) -> [Set<Int>] {
        let parts = s.split(separator: ",", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
        let masks = parts.count == 81 ? parts : Array(repeating: 0, count: 81)
        return masks.map { mask in
            var set = Set<Int>()
            for d in 1...9 where mask & (1 << (d - 1)) != 0 { set.insert(d) }
            return set
        }
    }
}
