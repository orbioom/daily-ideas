import Foundation

/// Puzzle difficulty controls grid size, word count, and which directions are allowed.
enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var gridSize: Int {
        switch self {
        case .easy: return 9
        case .medium: return 12
        case .hard: return 14
        }
    }

    var targetWordCount: Int {
        switch self {
        case .easy: return 7
        case .medium: return 10
        case .hard: return 12
        }
    }

    var allowsDiagonals: Bool {
        switch self {
        case .easy: return false
        case .medium, .hard: return true
        }
    }

    var allowsReverse: Bool {
        switch self {
        case .easy, .medium: return false
        case .hard: return true
        }
    }

    var symbolName: String {
        switch self {
        case .easy: return "leaf.fill"
        case .medium: return "flame.fill"
        case .hard: return "bolt.fill"
        }
    }

    /// Builds the set of allowed directions honoring the override flags from settings.
    func directions(allowDiagonals: Bool, allowReverse: Bool) -> [Direction] {
        let diag = allowsDiagonals && allowDiagonals
        let rev = allowsReverse && allowReverse
        return Direction.all.filter { dir in
            if dir.isDiagonal && !diag { return false }
            if dir.isReverse && !rev { return false }
            return true
        }
    }
}
