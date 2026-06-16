import Foundation

/// One player's live card within an in-progress game.
struct PlayerState: Identifiable {
    let id = UUID()
    var name: String
    var isCPU: Bool
    var cpuDifficulty: CPUDifficulty?

    /// Recorded scores per category (only filled categories appear).
    var scores: [ScoreCategory: Int] = [:]
    /// Number of awarded Yahtzee bonuses (each = +100).
    var yahtzeeBonuses: Int = 0

    var filledCount: Int { scores.count }
    var isComplete: Bool { scores.count >= ScoreCategory.allCases.count }

    func has(_ category: ScoreCategory) -> Bool { scores[category] != nil }

    var openCategories: [ScoreCategory] {
        ScoreCategory.allCases.filter { scores[$0] == nil }
    }

    var upperSubtotal: Int { Scorer.upperSubtotal(scores) }
    var upperBonus: Int { Scorer.upperBonus(scores) }

    var grandTotal: Int {
        let base = scores.values.reduce(0, +)
        return base + upperBonus + yahtzeeBonuses * Scorer.yahtzeeBonusValue
    }
}

enum CPUDifficulty: String, CaseIterable, Identifiable, Codable {
    case casual = "Casual", sharp = "Sharp", master = "Master"
    var id: String { rawValue }
    var subtitle: String {
        switch self {
        case .casual: return "Plays loose — good for learning"
        case .sharp: return "Solid expected-value play"
        case .master: return "Plays the odds hard"
        }
    }
    /// 0 = greedy/no lookahead noise, higher = more thorough hold search.
    var planningDepth: Int {
        switch self {
        case .casual: return 0
        case .sharp: return 1
        case .master: return 2
        }
    }
}
