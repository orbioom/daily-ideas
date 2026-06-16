import Foundation

/// Deterministic heuristic CPU. Given the dice, holds, and rolls remaining it chooses
/// which dice to hold (toward the highest-value reachable open category) and, on the
/// final roll, which open category to score. No randomness here — purely a function of
/// the visible state, so it stays reproducible alongside the engine's injected RNG.
enum CPUStrategy {

    /// Decide the hold mask for the current dice with `rollsRemaining` rolls still to come.
    /// Returns a length-5 bool array (true = keep this die).
    static func chooseHolds(dice: [Int], player: PlayerState, rollsRemaining: Int,
                            difficulty: CPUDifficulty) -> [Bool] {
        guard dice.count == 5 else { return [Bool](repeating: true, count: dice.count) }

        // Evaluate every subset of dice to keep; pick the one with the best estimated
        // value over the remaining rolls. 2^5 = 32 subsets — cheap and exhaustive.
        var bestMask = [Bool](repeating: false, count: 5)
        var bestScore = -Double.greatestFiniteMagnitude

        for subset in 0..<32 {
            var mask = [Bool](repeating: false, count: 5)
            for i in 0..<5 where (subset & (1 << i)) != 0 { mask[i] = true }
            let kept = (0..<5).filter { mask[$0] }.map { dice[$0] }
            let value = expectedValue(keeping: kept, dice: dice, player: player,
                                      rollsRemaining: rollsRemaining, difficulty: difficulty)
            if value > bestScore {
                bestScore = value
                bestMask = mask
            }
        }
        return bestMask
    }

    /// Pick the best open category to score the final dice into.
    static func chooseCategory(dice: [Int], player: PlayerState,
                               scoreFor: (ScoreCategory) -> Int) -> ScoreCategory {
        let open = player.openCategories
        guard let first = open.first else { return .chance }

        var best = first
        var bestValue = -Double.greatestFiniteMagnitude
        for cat in open {
            let raw = Double(scoreFor(cat))
            // Strategic adjustment: value upper-bonus progress; avoid dumping good dice
            // into Chance, and avoid wasting Yahtzee with a zero in it if salvageable.
            var adj = raw
            adj += strategicBonus(cat: cat, raw: scoreFor(cat), player: player)
            if adj > bestValue {
                bestValue = adj
                best = cat
            }
        }
        return best
    }

    // MARK: - Estimation

    /// Estimate value of keeping `kept` dice. With 0 rolls remaining the dice are final,
    /// so just take the best immediate category score. Otherwise estimate expected value
    /// of the kept core plus a contribution from the dice we'll re-roll.
    private static func expectedValue(keeping kept: [Int], dice: [Int], player: PlayerState,
                                      rollsRemaining: Int, difficulty: CPUDifficulty) -> Double {
        if rollsRemaining <= 0 {
            return Double(bestImmediateScore(dice: dice, player: player))
        }

        let counts = Scorer.faceCounts(kept)
        var value = 0.0

        // Reward building toward a single dominant face (toward 3/4/5-of-a-kind & Yahtzee).
        let maxOfAKind = counts.max() ?? 0
        let dominantFace = (1...6).max(by: { counts[$0] < counts[$1] }) ?? 6
        value += Double(maxOfAKind) * Double(dominantFace) * 1.6

        // Reward straight potential: count distinct consecutive faces kept.
        value += Double(longestRun(counts)) * 4.0

        // Reward keeping high pips generally (helps Chance / upper section).
        value += Double(kept.reduce(0, +)) * 0.5

        // Penalize keeping too many junk dice we should re-roll for improvement.
        let rerollCount = 5 - kept.count
        value += Double(rerollCount) * 1.2 * Double(rollsRemaining)

        // Difficulty: deeper planning leans harder into the dominant strategy.
        if difficulty.planningDepth >= 1 && maxOfAKind >= 3 {
            value += Double(maxOfAKind) * 3.0
        }
        if difficulty.planningDepth >= 2 {
            // Master values open Yahtzee/upper-bonus pursuit.
            if player.scores[.yahtzee] == nil && maxOfAKind >= 3 {
                value += 6.0
            }
            if let upper = ScoreCategory.upperCategories.first(where: { $0.upperFace == dominantFace }),
               player.scores[upper] == nil, player.upperSubtotal < Scorer.upperBonusThreshold {
                value += Double(maxOfAKind) * 1.5
            }
        }

        return value
    }

    /// Best score achievable scoring the given dice into any of the player's open categories.
    private static func bestImmediateScore(dice: [Int], player: PlayerState) -> Int {
        player.openCategories.map { Scorer.score($0, dice: dice) }.max() ?? 0
    }

    private static func strategicBonus(cat: ScoreCategory, raw: Int, player: PlayerState) -> Double {
        var bonus = 0.0
        // Don't burn Chance on small totals if other open boxes can take a zero cheaply.
        if cat == .chance && raw < 18 { bonus -= 4 }
        // Prefer scoring zero into low-value upper boxes (ones/twos) when forced, over a
        // valuable lower box.
        if raw == 0 {
            switch cat {
            case .ones: bonus += 3
            case .twos: bonus += 2.5
            case .yahtzee: bonus -= 8   // keep Yahtzee open if avoidable
            case .largeStraight: bonus -= 6
            case .fullHouse: bonus -= 4
            default: bonus += 0.5
            }
        }
        // Upper bonus chase: reward landing upper boxes that push toward 63.
        if cat.isUpper && raw > 0 && player.upperSubtotal < Scorer.upperBonusThreshold {
            bonus += 1.5
        }
        return bonus
    }

    private static func longestRun(_ counts: [Int]) -> Int {
        guard counts.count == 7 else { return 0 }
        var best = 0, streak = 0
        for face in 1...6 {
            if counts[face] >= 1 { streak += 1; best = max(best, streak) }
            else { streak = 0 }
        }
        return best
    }
}
