import SwiftUI

/// Puzzle difficulty. Hard & Expert are Pro-gated.
enum Difficulty: Int, CaseIterable, Identifiable, Codable {
    case easy = 0
    case medium = 1
    case hard = 2
    case expert = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }

    var subtitle: String {
        switch self {
        case .easy: return "Singles only"
        case .medium: return "Locked candidates"
        case .hard: return "Naked & hidden pairs"
        case .expert: return "The full challenge"
        }
    }

    var isPro: Bool {
        self == .hard || self == .expert
    }

    /// Hardest technique the generated puzzle should require.
    var maxTechnique: SolveTechnique {
        switch self {
        case .easy: return .hiddenSingle
        case .medium: return .lockedCandidate
        case .hard: return .pair
        case .expert: return .pair
        }
    }

    /// Approximate number of holes (empty cells) to aim for. The generator caps to a
    /// safe range and stops when uniqueness or technique target can no longer be met.
    var targetHoles: Int {
        switch self {
        case .easy: return 40
        case .medium: return 48
        case .hard: return 52
        case .expert: return 56
        }
    }

    var tint: Color {
        switch self {
        case .easy: return Theme.success
        case .medium: return Theme.accent
        case .hard: return Theme.warning
        case .expert: return Theme.error
        }
    }

    var symbol: String {
        switch self {
        case .easy: return "leaf"
        case .medium: return "circle.grid.cross"
        case .hard: return "flame"
        case .expert: return "bolt"
        }
    }
}

/// Logical techniques in increasing order of difficulty. Ordering is used for grading.
enum SolveTechnique: Int, Comparable, CaseIterable {
    case nakedSingle = 0
    case hiddenSingle = 1
    case lockedCandidate = 2
    case pair = 3

    static func < (lhs: SolveTechnique, rhs: SolveTechnique) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .nakedSingle: return "Naked Single"
        case .hiddenSingle: return "Hidden Single"
        case .lockedCandidate: return "Locked Candidate"
        case .pair: return "Naked / Hidden Pair"
        }
    }
}
