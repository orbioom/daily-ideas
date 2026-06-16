import Foundation
import Observation

/// The live game state machine: 5 dice, up to 3 rolls/turn, hold/unhold, scoring with
/// previews, Yahtzee-bonus + Joker rules, turn rotation, and winner determination.
///
/// Deterministic: all randomness flows through the injected `SeededRNG`.
@Observable
final class GameEngine {
    let mode: GameMode
    let maxRolls = 3
    let diceCount = 5

    private(set) var players: [PlayerState]
    private(set) var currentPlayerIndex: Int = 0

    /// Current dice face values (1...6). Always `diceCount` long once a turn starts.
    private(set) var dice: [Int]
    /// Per-die hold flags, parallel to `dice`.
    private(set) var held: [Bool]
    /// Rolls used in the current turn (0...maxRolls).
    private(set) var rollsUsed: Int = 0
    private(set) var isFinished: Bool = false
    /// Set when a roll has happened this turn (dice are live and scoreable).
    private(set) var hasRolledThisTurn: Bool = false

    private var rng: SeededRNG

    init(mode: GameMode, players: [PlayerState], rng: SeededRNG) {
        self.mode = mode
        self.players = players
        self.rng = rng
        self.dice = [Int](repeating: 1, count: diceCount)
        self.held = [Bool](repeating: false, count: diceCount)
    }

    // MARK: - Derived

    var currentPlayer: PlayerState? {
        players.indices.contains(currentPlayerIndex) ? players[currentPlayerIndex] : nil
    }

    var rollsRemaining: Int { max(0, maxRolls - rollsUsed) }
    var canRoll: Bool { !isFinished && rollsRemaining > 0 && !(currentPlayer?.isComplete ?? true) }

    /// Whether the current player may still score (must have rolled at least once).
    var canScore: Bool { !isFinished && hasRolledThisTurn }

    var isCurrentPlayerCPU: Bool { currentPlayer?.isCPU ?? false }

    // MARK: - Rolling

    /// Roll all non-held dice. Returns the indices that actually changed (for animation).
    @discardableResult
    func roll() -> [Int] {
        guard canRoll else { return [] }
        var rolledIndices: [Int] = []
        if rollsUsed == 0 {
            // First roll: every die rolls; clear holds.
            held = [Bool](repeating: false, count: diceCount)
            for i in dice.indices {
                dice[i] = rng.rollDie()
                rolledIndices.append(i)
            }
        } else {
            for i in dice.indices where !held[i] {
                dice[i] = rng.rollDie()
                rolledIndices.append(i)
            }
        }
        rollsUsed += 1
        hasRolledThisTurn = true
        return rolledIndices
    }

    func toggleHold(_ index: Int) {
        guard hasRolledThisTurn, !isFinished else { return }
        guard held.indices.contains(index) else { return }
        // Cannot toggle after the third roll? Holding is irrelevant then but harmless.
        held[index].toggle()
    }

    func setHolds(_ holds: [Bool]) {
        guard holds.count == held.count else { return }
        held = holds
    }

    // MARK: - Previews

    /// The score the current dice would yield in `category`, accounting for the
    /// Yahtzee Joker rule. Only meaningful when `hasRolledThisTurn`.
    func preview(_ category: ScoreCategory) -> Int {
        guard let player = currentPlayer, player.scores[category] == nil else { return 0 }
        return scoreWithJoker(category, dice: dice, for: player)
    }

    /// True if scoring `category` right now would also award a +100 Yahtzee bonus.
    func previewAwardsYahtzeeBonus(_ category: ScoreCategory) -> Bool {
        guard let player = currentPlayer else { return false }
        return Scorer.isYahtzee(dice)
            && (player.scores[.yahtzee] ?? 0) == Scorer.yahtzeeValue
            && player.scores[category] == nil
    }

    /// Joker-aware score. Standard rules:
    ///  • A Yahtzee that comes after the Yahtzee box is already scored 50 earns a +100 bonus.
    ///  • Joker placement: with such a Yahtzee, the player must use the matching upper box
    ///    if open; otherwise any lower box. When the matching upper box is already filled,
    ///    Full House=25, Sm. Straight=30, Lg. Straight=40 are awarded as Jokers even though
    ///    the dice aren't naturally those patterns.
    func scoreWithJoker(_ category: ScoreCategory, dice: [Int], for player: PlayerState) -> Int {
        let natural = Scorer.score(category, dice: dice)
        guard Scorer.isYahtzee(dice) else { return natural }

        // Determine the matching upper face of the Yahtzee.
        let counts = Scorer.faceCounts(dice)
        let face = (1...6).first(where: { counts[$0] == 5 }) ?? 0
        let matchingUpper: ScoreCategory? = ScoreCategory.upperCategories.first { $0.upperFace == face }

        let yahtzeeAlreadyScored = (player.scores[.yahtzee] ?? 0) == Scorer.yahtzeeValue
        let matchingUpperOpen = matchingUpper.map { player.scores[$0] == nil } ?? false

        // Joker only relieves the lower-section requirements when the Yahtzee box is
        // already used AND the matching upper box is NOT open (per standard rules).
        let jokerActive = yahtzeeAlreadyScored && !matchingUpperOpen

        if jokerActive {
            switch category {
            case .fullHouse: return Scorer.fullHouseValue
            case .smallStraight: return Scorer.smallStraightValue
            case .largeStraight: return Scorer.largeStraightValue
            default: return natural
            }
        }
        return natural
    }

    // MARK: - Scoring a category (locks it)

    /// Record `category` for the current player using the current dice, then advance.
    @discardableResult
    func score(_ category: ScoreCategory) -> Bool {
        guard canScore else { return false }
        guard players.indices.contains(currentPlayerIndex) else { return false }
        var player = players[currentPlayerIndex]
        guard player.scores[category] == nil else { return false }

        let value = scoreWithJoker(category, dice: dice, for: player)

        // Award Yahtzee bonus if this is an extra Yahtzee after the box is already 50.
        if Scorer.isYahtzee(dice) && (player.scores[.yahtzee] ?? 0) == Scorer.yahtzeeValue {
            player.yahtzeeBonuses += 1
        }

        player.scores[category] = value
        players[currentPlayerIndex] = player
        advanceTurn()
        return true
    }

    // MARK: - Turn rotation

    private func advanceTurn() {
        // Reset dice/turn state.
        rollsUsed = 0
        hasRolledThisTurn = false
        held = [Bool](repeating: false, count: diceCount)
        dice = [Int](repeating: 1, count: diceCount)

        if players.allSatisfy({ $0.isComplete }) {
            isFinished = true
            return
        }

        // Advance to the next player who still has open categories.
        var next = currentPlayerIndex
        for _ in 0..<players.count {
            next = (next + 1) % players.count
            if players.indices.contains(next) && !players[next].isComplete {
                currentPlayerIndex = next
                return
            }
        }
        // No one left -> finished (defensive; allSatisfy above should have caught it).
        isFinished = true
    }

    // MARK: - Results

    /// Players sorted by grand total descending, stable by original order on ties.
    var ranking: [PlayerState] {
        players.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.grandTotal != rhs.element.grandTotal {
                    return lhs.element.grandTotal > rhs.element.grandTotal
                }
                return lhs.offset < rhs.offset
            }
            .map { $0.element }
    }

    /// Winner name; on a tie returns the joined names. Nil if not finished.
    var winner: PlayerState? {
        guard isFinished else { return nil }
        return ranking.first
    }

    var isTie: Bool {
        guard isFinished, let top = ranking.first else { return false }
        return ranking.filter { $0.grandTotal == top.grandTotal }.count > 1
    }
}
