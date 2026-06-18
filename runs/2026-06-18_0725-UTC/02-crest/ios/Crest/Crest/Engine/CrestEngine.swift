import Foundation

/// Pure, deterministic, fully index-guarded TriPeaks engine.
/// No SwiftUI / SwiftData here — this is testable game logic only.
struct CrestEngine {

    // MARK: Scoring constants
    static let basePerCard = 50
    static let comboStep = 25        // added per combo level
    static let stockPenalty = 0      // drawing is free but resets combo
    static let winBonus = 500

    let spec: BoardSpec
    private(set) var state: BoardState
    let wrap: Bool

    /// Snapshot stack for undo. Each entry is the state BEFORE a reversible action.
    private(set) var undoStack: [BoardState] = []

    // MARK: - Init / Deal

    /// Deterministic deal for a layout + deal number. The same inputs always
    /// produce the same board.
    init(layout: BoardLayout, dealNumber: Int, isDaily: Bool, wrap: Bool) {
        self.spec = layout.spec
        self.wrap = wrap
        let seed = SeedFactory.seed(layout: layout, dealNumber: dealNumber)
        var rng = SplitMix64(seed: seed)
        var deck = Card.fullDeck.shuffled(using: &rng)

        let tableauCount = min(spec.count, deck.count)
        var tableau: [Card?] = []
        tableau.reserveCapacity(tableauCount)
        for _ in 0..<tableauCount {
            tableau.append(deck.removeFirst())
        }
        // Remaining cards: all but one go to stock, last becomes the initial waste.
        var stock = deck
        var waste: [Card] = []
        if !stock.isEmpty {
            waste.append(stock.removeLast())
        }

        self.state = BoardState(
            layout: layout,
            dealNumber: dealNumber,
            isDaily: isDaily,
            tableau: tableau,
            stock: stock,
            waste: waste,
            score: 0,
            combo: 0,
            longestCombo: 0,
            cardsCleared: 0,
            elapsedAccum: 0
        )
    }

    /// Rehydrate an engine from a saved state (resume).
    init(state: BoardState, wrap: Bool) {
        self.spec = state.layout.spec
        self.wrap = wrap
        self.state = state
    }

    // MARK: - Playability

    /// True when position `i` is uncovered (all covering positions cleared) and still holds a card.
    func isPlayable(_ i: Int) -> Bool {
        guard i >= 0, i < state.tableau.count else { return false }
        guard state.tableau[i] != nil else { return false }
        guard i < spec.covers.count else { return false }
        for child in spec.covers[i] {
            guard child >= 0, child < state.tableau.count else { continue }
            if state.tableau[child] != nil { return false } // still covered
        }
        return true
    }

    /// Adjacency check (with optional wrap) of a tableau card onto the current waste card.
    func playable(card: Card, onWaste waste: Card?) -> Bool {
        guard let waste else { return false }
        return card.isAdjacent(to: waste, wrap: wrap)
    }

    /// All currently legal tableau plays (indices).
    func legalMoves() -> [Int] {
        guard let top = state.topWaste else { return [] }
        var moves: [Int] = []
        for i in 0..<state.tableau.count {
            guard let card = state.tableau[i] else { continue }
            if isPlayable(i) && card.isAdjacent(to: top, wrap: wrap) {
                moves.append(i)
            }
        }
        return moves
    }

    /// True if there's any legal tableau play available right now.
    var hasLegalMove: Bool { !legalMoves().isEmpty }

    /// A hint: the first legal move, if any.
    func hint() -> Int? { legalMoves().first }

    // MARK: - Outcome

    var outcome: GameOutcome {
        if state.tableau.allSatisfy({ $0 == nil }) { return .won }
        if state.stock.isEmpty && !hasLegalMove { return .lost }
        return .playing
    }

    // MARK: - Mutations

    /// Play the tableau card at position `i` onto the waste. Returns true on success.
    @discardableResult
    mutating func play(_ i: Int) -> Bool {
        guard i >= 0, i < state.tableau.count else { return false }
        guard let card = state.tableau[i] else { return false }
        guard isPlayable(i) else { return false }
        guard let top = state.topWaste, card.isAdjacent(to: top, wrap: wrap) else { return false }

        pushUndo()
        state.tableau[i] = nil
        state.waste.append(card)
        state.combo += 1
        state.longestCombo = max(state.longestCombo, state.combo)
        state.cardsCleared += 1
        // Score: base + combo bonus that grows with the streak.
        let comboBonus = max(0, state.combo - 1) * Self.comboStep
        state.score += Self.basePerCard + comboBonus
        if outcome == .won {
            state.score += Self.winBonus
        }
        return true
    }

    /// Draw the top stock card to the waste. Resets combo. Returns true on success.
    @discardableResult
    mutating func drawFromStock() -> Bool {
        guard !state.stock.isEmpty else { return false }
        pushUndo()
        let card = state.stock.removeLast()
        state.waste.append(card)
        state.combo = 0
        if Self.stockPenalty != 0 {
            state.score = max(0, state.score - Self.stockPenalty)
        }
        return true
    }

    // MARK: - Undo

    private mutating func pushUndo() {
        undoStack.append(state)
        // Cap the undo depth so memory stays bounded over a long game.
        if undoStack.count > 200 {
            undoStack.removeFirst(undoStack.count - 200)
        }
    }

    var canUndo: Bool { !undoStack.isEmpty }

    @discardableResult
    mutating func undo() -> Bool {
        guard let previous = undoStack.popLast() else { return false }
        // Preserve accumulated wall-clock time across undo (time keeps flowing).
        var restored = previous
        restored.elapsedAccum = state.elapsedAccum
        state = restored
        return true
    }

    // MARK: - Timer accounting

    mutating func setElapsedAccum(_ value: Double) {
        state.elapsedAccum = max(0, value)
    }
}
