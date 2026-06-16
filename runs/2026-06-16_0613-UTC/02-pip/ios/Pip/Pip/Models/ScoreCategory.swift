import Foundation

/// The 13 Yahtzee scoring categories, in canonical scorecard order.
enum ScoreCategory: String, CaseIterable, Identifiable, Codable {
    // Upper section
    case ones, twos, threes, fours, fives, sixes
    // Lower section
    case threeOfAKind, fourOfAKind, fullHouse, smallStraight, largeStraight, chance, yahtzee

    var id: String { rawValue }

    var isUpper: Bool {
        switch self {
        case .ones, .twos, .threes, .fours, .fives, .sixes: return true
        default: return false
        }
    }

    /// The face value an upper category counts (Ones=1 … Sixes=6); nil for lower section.
    var upperFace: Int? {
        switch self {
        case .ones: return 1
        case .twos: return 2
        case .threes: return 3
        case .fours: return 4
        case .fives: return 5
        case .sixes: return 6
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .ones: return "Ones"
        case .twos: return "Twos"
        case .threes: return "Threes"
        case .fours: return "Fours"
        case .fives: return "Fives"
        case .sixes: return "Sixes"
        case .threeOfAKind: return "Three of a Kind"
        case .fourOfAKind: return "Four of a Kind"
        case .fullHouse: return "Full House"
        case .smallStraight: return "Small Straight"
        case .largeStraight: return "Large Straight"
        case .chance: return "Chance"
        case .yahtzee: return "Yahtzee"
        }
    }

    var shortTitle: String {
        switch self {
        case .threeOfAKind: return "3 of a Kind"
        case .fourOfAKind: return "4 of a Kind"
        case .smallStraight: return "Sm. Straight"
        case .largeStraight: return "Lg. Straight"
        default: return title
        }
    }

    /// Human-readable scoring rule shown on the How-to-Play reference.
    var ruleText: String {
        switch self {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            let face = upperFace ?? 0
            return "Sum of all \(title.lowercased()). Reach 63+ in the upper section for a 35-point bonus. (Each \(title.singularLower()) is worth \(face).)"
        case .threeOfAKind: return "At least three of one face. Scores the sum of ALL five dice."
        case .fourOfAKind: return "At least four of one face. Scores the sum of ALL five dice."
        case .fullHouse: return "Three of one face and two of another. Scores 25."
        case .smallStraight: return "Four in a row (e.g. 1-2-3-4). Scores 30."
        case .largeStraight: return "Five in a row (1-2-3-4-5 or 2-3-4-5-6). Scores 40."
        case .chance: return "Anything goes. Scores the sum of all five dice."
        case .yahtzee: return "All five dice the same. Scores 50. Each extra Yahtzee earns a 100-point bonus."
        }
    }

    static var upperCategories: [ScoreCategory] { allCases.filter { $0.isUpper } }
    static var lowerCategories: [ScoreCategory] { allCases.filter { !$0.isUpper } }
}

private extension String {
    func singularLower() -> String {
        // "Ones" -> "one", "Twos" -> "two", etc.
        var s = lowercased()
        if s.hasSuffix("s") { s.removeLast() }
        return s
    }
}
