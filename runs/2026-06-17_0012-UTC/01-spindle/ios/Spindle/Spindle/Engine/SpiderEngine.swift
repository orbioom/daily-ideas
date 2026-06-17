import Foundation

/// Pure, fully unit-test-able Spider Solitaire engine.
///
/// Holds the entire board as a `Codable` value type so it can be snapshotted
/// for undo and JSON-encoded for SavedGame. All array access is guarded —
/// the engine never traps on an empty column or empty stock.
struct SpiderEngine: Codable, Equatable {

    // MARK: - State

    /// 10 tableau columns, top of pile = last element.
    private(set) var columns: [[Card]]
    /// The remaining stock, dealt 10 at a time. Count is always a multiple of 10
    /// until exhausted (an initial 50 = 5 deals).
    private(set) var stock: [Card]
    /// Completed K..A runs removed to foundations. Win at 8.
    private(set) var foundations: [Suit]
    private(set) var moves: Int
    private(set) var score: Int
    let suitMode: SuitMode

    static let columnCount = 10
    static let foundationGoal = 8

    // MARK: - Init / deal

    /// Builds a fresh game deterministically from a seed.
    init(suitMode: SuitMode, seed: UInt64) {
        self.suitMode = suitMode
        self.columns = Array(repeating: [], count: SpiderEngine.columnCount)
        self.stock = []
        self.foundations = []
        self.moves = 0
        self.score = 500

        var deck = SpiderEngine.buildDeck(for: suitMode)
        var rng = SplitMix64(seed: seed)
        deck = deck.deterministicShuffled(using: &rng)
        deal(from: deck)
    }

    /// Builds the 104-card deck for a suit mode. Suits are duplicated to reach 104
    /// (e.g. 1-suit = 8 copies of each spade rank; 2-suit = 4 of each; 4-suit = 2).
    static func buildDeck(for mode: SuitMode) -> [Card] {
        let suits = mode.suits
        let copiesPerSuit = 104 / (suits.count * 13)   // 8, 4, or 2
        var cards: [Card] = []
        cards.reserveCapacity(104)
        for suit in suits {
            for _ in 0..<copiesPerSuit {
                for rank in 1...13 {
                    cards.append(Card(suit: suit, rank: rank, faceUp: false))
                }
            }
        }
        return cards
    }

    /// Initial deal: 54 cards (4 columns of 6, 6 columns of 5), top card of each
    /// column face-up; the remaining 50 become the stock (5 deals of 10).
    private mutating func deal(from deck: [Card]) {
        var deck = deck
        let counts = [6, 6, 6, 6, 5, 5, 5, 5, 5, 5]
        var index = 0
        for col in 0..<SpiderEngine.columnCount {
            let count = counts[safe: col] ?? 5
            var pile: [Card] = []
            for _ in 0..<count {
                if let card = deck[safe: index] {
                    pile.append(card)
                    index += 1
                }
            }
            // Flip the top card face-up.
            if !pile.isEmpty {
                pile[pile.count - 1].faceUp = true
            }
            columns[col] = pile
        }
        // Remaining cards form the stock (face-down).
        if index < deck.count {
            stock = Array(deck[index...])
        } else {
            stock = []
        }
    }

    // MARK: - Derived state

    var isWon: Bool { foundations.count >= SpiderEngine.foundationGoal }

    /// Number of full 10-card deals still available from the stock.
    var dealsRemaining: Int { stock.count / SpiderEngine.columnCount }

    var canDealFromStock: Bool {
        !stock.isEmpty && stock.count >= SpiderEngine.columnCount && !columns.contains(where: { $0.isEmpty })
    }

    /// Reason dealing is blocked, for a calm user message (nil when allowed).
    var dealBlockedReason: String? {
        if stock.isEmpty || stock.count < SpiderEngine.columnCount {
            return "No more cards to deal."
        }
        if columns.contains(where: { $0.isEmpty }) {
            return "Fill every empty column before dealing."
        }
        return nil
    }

    // MARK: - Run logic

    /// The face-up card at `index` in `column`, if any.
    func card(column: Int, index: Int) -> Card? {
        columns[safe: column]?[safe: index]
    }

    /// True if the cards from `index` to the end of `column` form a movable unit:
    /// they must be face-up, descending by exactly one, AND all the same suit
    /// (a non-same-suit ordered sequence can only be moved one card at a time).
    func isMovableRun(column: Int, fromIndex index: Int) -> Bool {
        guard let pile = columns[safe: column], index >= 0, index < pile.count else { return false }
        let slice = pile[index...]
        guard let first = slice.first, first.faceUp else { return false }
        var previous: Card?
        for card in slice {
            guard card.faceUp else { return false }
            if let prev = previous {
                if card.suit != prev.suit { return false }
                if card.rank != prev.rank - 1 { return false }
            }
            previous = card
        }
        return true
    }

    /// The lowest index in `column` from which a same-suit descending run starts
    /// that includes the top card. Used for "grab the longest run by default".
    func longestRunStart(column: Int) -> Int? {
        guard let pile = columns[safe: column], !pile.isEmpty else { return nil }
        var start = pile.count - 1
        guard pile[start].faceUp else { return nil }
        var i = pile.count - 1
        while i > 0 {
            let upper = pile[i]
            let lower = pile[i - 1]
            if lower.faceUp, upper.suit == lower.suit, upper.rank == lower.rank - 1 {
                start = i - 1
                i -= 1
            } else {
                break
            }
        }
        return start
    }

    /// Whether the unit starting at `fromIndex` in `fromColumn` may legally land on
    /// `toColumn`. Building is down regardless of suit; empty columns accept anything.
    func canMove(fromColumn: Int, fromIndex: Int, toColumn: Int) -> Bool {
        guard fromColumn != toColumn else { return false }
        guard isMovableRun(column: fromColumn, fromIndex: fromIndex) else { return false }
        guard let from = columns[safe: fromColumn], let moving = from[safe: fromIndex] else { return false }
        guard let dest = columns[safe: toColumn] else { return false }
        if let destTop = dest.last {
            guard destTop.faceUp else { return false }
            // Build down by one, any suit.
            return destTop.rank == moving.rank + 1
        }
        // Empty column accepts any card / run.
        return true
    }

    // MARK: - Mutations

    /// Performs a move if legal. Returns true on success.
    @discardableResult
    mutating func move(fromColumn: Int, fromIndex: Int, toColumn: Int) -> Bool {
        guard canMove(fromColumn: fromColumn, fromIndex: fromIndex, toColumn: toColumn) else { return false }
        guard var source = columns[safe: fromColumn], fromIndex < source.count else { return false }

        let moving = Array(source[fromIndex...])
        source.removeSubrange(fromIndex...)
        // Flip the newly exposed top card of the source column.
        if !source.isEmpty, !source[source.count - 1].faceUp {
            source[source.count - 1].faceUp = true
        }
        columns[fromColumn] = source
        columns[toColumn].append(contentsOf: moving)

        moves += 1
        score = max(0, score - 1)
        collectCompletedRuns()
        return true
    }

    /// Deals one face-up card to each column from the stock, if allowed.
    /// Returns true if a deal happened.
    @discardableResult
    mutating func dealFromStock() -> Bool {
        guard canDealFromStock else { return false }
        for col in 0..<SpiderEngine.columnCount {
            if !stock.isEmpty {
                var card = stock.removeFirst()
                card.faceUp = true
                columns[col].append(card)
            }
        }
        moves += 1
        score = max(0, score - 1)
        collectCompletedRuns()
        return true
    }

    /// Scans every column for a complete same-suit K..A run at its top and removes
    /// it to a foundation. Awards +100 per completed run.
    mutating func collectCompletedRuns() {
        var changed = true
        while changed {
            changed = false
            for col in 0..<columns.count {
                if let removedSuit = removeCompletedRunIfPresent(in: col) {
                    foundations.append(removedSuit)
                    score += 100
                    // Flip the newly exposed top card.
                    if var pile = columns[safe: col], !pile.isEmpty, !pile[pile.count - 1].faceUp {
                        pile[pile.count - 1].faceUp = true
                        columns[col] = pile
                    }
                    changed = true
                }
            }
        }
    }

    /// If the top 13 cards of `column` are a same-suit K(13)…A(1) descending run,
    /// removes them and returns the suit. Otherwise returns nil.
    private mutating func removeCompletedRunIfPresent(in column: Int) -> Suit? {
        guard let pile = columns[safe: column], pile.count >= 13 else { return nil }
        let start = pile.count - 13
        let slice = Array(pile[start...])
        guard let king = slice.first, king.rank == 13, king.faceUp else { return nil }
        let suit = king.suit
        for (offset, card) in slice.enumerated() {
            guard card.faceUp else { return nil }
            if card.suit != suit { return nil }
            if card.rank != 13 - offset { return nil }
        }
        columns[column].removeSubrange(start...)
        return suit
    }

    // MARK: - Hint

    /// A legal move the player could make right now.
    struct Hint: Equatable {
        enum Kind: Equatable {
            case move(fromColumn: Int, fromIndex: Int, toColumn: Int)
            case deal
        }
        let kind: Kind
        let message: String
    }

    /// Finds any legal tableau→tableau move (preferring ones that complete runs or
    /// empty a column), else suggests dealing if possible. Returns nil if stuck.
    func findHint() -> Hint? {
        var best: Hint?
        for fromCol in 0..<columns.count {
            guard let pile = columns[safe: fromCol], !pile.isEmpty else { continue }
            // Consider every face-up start that forms a movable run.
            for idx in 0..<pile.count where isMovableRun(column: fromCol, fromIndex: idx) {
                for toCol in 0..<columns.count where toCol != fromCol {
                    if canMove(fromColumn: fromCol, fromIndex: idx, toColumn: toCol) {
                        // Prefer a non-trivial move: don't suggest shuffling onto an
                        // empty column when a real build exists.
                        let toEmpty = columns[safe: toCol]?.isEmpty ?? false
                        let movingCard = pile[safe: idx]
                        let label = movingCard?.spokenName ?? "a card"
                        let hint = Hint(
                            kind: .move(fromColumn: fromCol, fromIndex: idx, toColumn: toCol),
                            message: toEmpty
                                ? "Move \(label) to the empty column."
                                : "Move \(label) onto column \(toCol + 1)."
                        )
                        if !toEmpty { return hint }      // strongly prefer real builds
                        if best == nil { best = hint }
                    }
                }
            }
        }
        if let best { return best }
        if canDealFromStock {
            return Hint(kind: .deal, message: "No moves left — deal a new row from the stock.")
        }
        return nil
    }

    /// Best legal destination column for the run starting at `fromIndex`, for
    /// double-tap auto-move. Prefers a real build over an empty column.
    func bestDestination(fromColumn: Int, fromIndex: Int) -> Int? {
        guard isMovableRun(column: fromColumn, fromIndex: fromIndex) else { return nil }
        var emptyTarget: Int?
        for toCol in 0..<columns.count where toCol != fromColumn {
            if canMove(fromColumn: fromColumn, fromIndex: fromIndex, toColumn: toCol) {
                if columns[safe: toCol]?.isEmpty ?? false {
                    if emptyTarget == nil { emptyTarget = toCol }
                } else {
                    return toCol
                }
            }
        }
        return emptyTarget
    }
}
