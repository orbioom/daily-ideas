import Foundation

/// Pure, deterministic Yahtzee scoring. Every function is index-guarded and total.
///
/// Verified-by-hand cases (see comments at each rule):
///  • Full House: {3,3,3,2,2} -> 25 ; {4,4,4,4,4} is NOT a natural full house unless Joker applies.
///  • Small Straight: {1,2,3,4,6} -> 30 ; {1,1,2,3,4} -> 30 ; {2,2,3,4,5} -> 30.
///  • Large Straight: {1,2,3,4,5} -> 40 ; {2,3,4,5,6} -> 40 ; {1,2,3,4,6} -> 0.
///  • Yahtzee: {5,5,5,5,5} -> 50.
///  • Yahtzee bonus + Joker handled by GameEngine using `isYahtzee` + `jokerEligible`.
enum Scorer {
    static let fullHouseValue = 25
    static let smallStraightValue = 30
    static let largeStraightValue = 40
    static let yahtzeeValue = 50
    static let yahtzeeBonusValue = 100
    static let upperBonusThreshold = 63
    static let upperBonusValue = 35

    /// Counts of each face. `counts[face]` for face 1...6. Index 0 unused.
    static func faceCounts(_ dice: [Int]) -> [Int] {
        var counts = [Int](repeating: 0, count: 7)
        for d in dice where d >= 1 && d <= 6 {
            counts[d] += 1
        }
        return counts
    }

    static func sum(_ dice: [Int]) -> Int {
        dice.reduce(0) { $0 + (($1 >= 1 && $1 <= 6) ? $1 : 0) }
    }

    static func isYahtzee(_ dice: [Int]) -> Bool {
        guard dice.count == 5 else { return false }
        let counts = faceCounts(dice)
        return counts.contains(5)
    }

    /// Natural score for a category given the dice (no Joker handling).
    /// `dice` is expected to be 5 values in 1...6; defensive against other inputs.
    static func score(_ category: ScoreCategory, dice: [Int]) -> Int {
        let counts = faceCounts(dice)
        switch category {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            // Sum of dice matching the face. {3,3,3,2,2} for Threes -> 9.
            let face = category.upperFace ?? 0
            guard face >= 1 && face <= 6 else { return 0 }
            return counts[face] * face

        case .threeOfAKind:
            // Needs ANY face appearing >= 3 times; scores sum of all dice.
            return counts.contains(where: { $0 >= 3 }) ? sum(dice) : 0

        case .fourOfAKind:
            // Needs ANY face appearing >= 4 times; scores sum of all dice.
            return counts.contains(where: { $0 >= 4 }) ? sum(dice) : 0

        case .fullHouse:
            // Exactly a triple + a pair. {3,3,3,2,2} -> 25. Five-of-a-kind is NOT a
            // natural full house (it has a 5, no distinct pair) -> 0 here. Joker rules
            // (handled in GameEngine) may award 25 when the Yahtzee box is already used.
            let hasThree = counts.contains(3)
            let hasTwo = counts.contains(2)
            return (hasThree && hasTwo) ? fullHouseValue : 0

        case .smallStraight:
            // Any 4 consecutive faces present. Sets: 1234,2345,3456.
            return hasRun(counts, length: 4) ? smallStraightValue : 0

        case .largeStraight:
            // All 5 consecutive: 12345 or 23456.
            return hasRun(counts, length: 5) ? largeStraightValue : 0

        case .chance:
            return sum(dice)

        case .yahtzee:
            return isYahtzee(dice) ? yahtzeeValue : 0
        }
    }

    /// True if the face counts contain `length` consecutive faces each appearing >= 1.
    private static func hasRun(_ counts: [Int], length: Int) -> Bool {
        guard counts.count == 7 else { return false }
        var streak = 0
        for face in 1...6 {
            if counts[face] >= 1 {
                streak += 1
                if streak >= length { return true }
            } else {
                streak = 0
            }
        }
        return false
    }

    /// Upper-section subtotal across a set of recorded scores.
    static func upperSubtotal(_ scores: [ScoreCategory: Int]) -> Int {
        ScoreCategory.upperCategories.reduce(0) { $0 + (scores[$1] ?? 0) }
    }

    static func upperBonus(_ scores: [ScoreCategory: Int]) -> Int {
        upperSubtotal(scores) >= upperBonusThreshold ? upperBonusValue : 0
    }
}
