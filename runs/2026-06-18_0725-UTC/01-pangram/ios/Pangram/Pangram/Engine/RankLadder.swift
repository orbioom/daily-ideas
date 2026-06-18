import Foundation

/// The rank ladder, scaled to a percentage of the puzzle's maximum possible score.
/// Thresholds mirror the familiar Spelling-Bee ladder (Genius ≈ 70%, Queen Bee = 100%).
enum Rank: Int, CaseIterable, Identifiable {
    case beginner, goodStart, movingUp, good, solid, nice, great, amazing, genius, queenBee

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .beginner: return "Beginner"
        case .goodStart: return "Good Start"
        case .movingUp: return "Moving Up"
        case .good: return "Good"
        case .solid: return "Solid"
        case .nice: return "Nice"
        case .great: return "Great"
        case .amazing: return "Amazing"
        case .genius: return "Genius"
        case .queenBee: return "Queen Bee"
        }
    }

    /// Fraction of max score required to reach this rank.
    var fraction: Double {
        switch self {
        case .beginner: return 0.0
        case .goodStart: return 0.02
        case .movingUp: return 0.05
        case .good: return 0.08
        case .solid: return 0.15
        case .nice: return 0.25
        case .great: return 0.40
        case .amazing: return 0.50
        case .genius: return 0.70
        case .queenBee: return 1.0
        }
    }

    var isGeniusOrAbove: Bool { rawValue >= Rank.genius.rawValue }
}

enum RankLadder {
    /// Highest rank achieved for a given score against a maximum.
    static func rank(score: Int, max maxScore: Int) -> Rank {
        guard maxScore > 0 else { return .beginner }
        let pct = Double(score) / Double(maxScore)
        var current: Rank = .beginner
        for r in Rank.allCases where pct + 1e-9 >= r.fraction {
            current = r
        }
        return current
    }

    /// Point threshold to reach a rank for a given maximum.
    static func threshold(for rank: Rank, max maxScore: Int) -> Int {
        guard maxScore > 0 else { return 0 }
        return Int((rank.fraction * Double(maxScore)).rounded(.up))
    }

    /// The next rank above the current one, if any.
    static func next(after rank: Rank) -> Rank? {
        Rank(rawValue: rank.rawValue + 1)
    }
}
