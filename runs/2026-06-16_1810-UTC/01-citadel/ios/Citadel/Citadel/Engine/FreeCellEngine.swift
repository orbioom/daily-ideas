import Foundation

/// Pure FreeCell logic: deal generation, rule validation, move application,
/// supermoves, and safe autoplay. Stateless — every function takes/returns values.
enum FreeCellEngine {

    // MARK: - Microsoft deal generator

    /// Classic Microsoft FreeCell LCG. Given a deal number, reproduces the famous deal layout.
    /// Deal numbers 1...1_000_000 are supported by the game; the generator itself accepts any
    /// non-negative seed.
    static func deal(number: Int) -> Board {
        // Seed the LCG with the (clamped) deal number.
        var state = UInt64(max(0, number)) & 0x7FFF_FFFF

        func rand() -> Int {
            state = (state &* 214013 &+ 2531011) & 0x7FFF_FFFF
            return Int((state >> 16) & 0x7FFF)
        }

        // Build the deck in MS order: rank-major, suit order clubs, diamonds, hearts, spades.
        // index = (rank-1)*4 + suitIndex
        var deck: [Card] = []
        deck.reserveCapacity(52)
        for rank in 1...13 {
            for suitIndex in 0..<4 {
                deck.append(Card(suit: Suit.fromMicrosoftIndex(suitIndex), rank: rank))
            }
        }

        // Deal into 8 columns, left to right, by repeatedly picking rand() % cardsLeft,
        // swapping the picked card with the last remaining card, then removing the last.
        var cascades: [[Card]] = Array(repeating: [], count: Board.cascadeCount)
        var cardsLeft = deck.count
        var column = 0
        while cardsLeft > 0 {
            let index = rand() % cardsLeft
            let picked = deck[index]
            // swap-remove: move the last remaining card into the picked slot, shrink the deck.
            deck[index] = deck[cardsLeft - 1]
            cardsLeft -= 1
            cascades[column].append(picked)
            column = (column + 1) % Board.cascadeCount
        }

        return Board(cascades: cascades)
    }

    /// A random deal across the supported range.
    static func randomDealNumber() -> Int {
        Int.random(in: 1...1_000_000)
    }

    /// A deterministic "today's deal" derived from a calendar date.
    /// Same date always yields the same deal number in 1...1_000_000.
    static func dealNumber(for date: Date, calendar: Calendar = .current) -> Int {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2000
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        // Mix the components into a stable value within range.
        let raw = (y * 10000 + m * 100 + d)
        return (raw % 1_000_000) + 1
    }

    // MARK: - Rule helpers

    /// A card may go onto a cascade if the target's top card is opposite color and one rank higher.
    static func canStack(_ moving: Card, onCascadeTop top: Card?) -> Bool {
        guard let top = top else { return true } // empty column accepts anything
        return moving.isRed != top.isRed && moving.rank == top.rank - 1
    }

    /// A card may go onto a foundation if it is the next ascending rank of the same suit.
    static func canPlaceOnFoundation(_ card: Card, board: Board) -> Bool {
        board.foundationRank(card.suit) == card.rank - 1
    }

    /// Validate that an array of cards forms a valid descending, alternating-color run
    /// (ordered bottom-to-top, i.e. the way it sits in a cascade).
    static func isValidRun(_ cards: [Card]) -> Bool {
        guard cards.count >= 1 else { return false }
        for i in 1..<cards.count {
            let lower = cards[i - 1]
            let upper = cards[i]
            if !(upper.rank == lower.rank - 1 && upper.isRed != lower.isRed) {
                return false
            }
        }
        return true
    }

    // MARK: - Supermove capacity

    /// Maximum number of cards movable as a single sequence.
    /// (freeFreeCells + 1) * 2^(emptyCascadeColumns).
    /// When the destination is itself an empty column, that column can't be used as a
    /// staging area, so capacity uses 2^(emptyColumns - 1).
    static func maxMovable(board: Board, destinationIsEmptyColumn: Bool) -> Int {
        let free = board.freeFreeCellCount
        var emptyCols = board.emptyCascadeCount
        if destinationIsEmptyColumn {
            emptyCols = max(0, emptyCols - 1)
        }
        // (free + 1) * 2^emptyCols — guard the shift against absurd values (max 7 empty cols).
        let exponent = min(emptyCols, 7)
        let multiplier = 1 << exponent
        return (free + 1) * multiplier
    }

    // MARK: - Move application

    /// Attempt to apply a move to a board. Returns the new board on success, or throws a
    /// calm typed error that callers catch. Never crashes on bad input.
    static func apply(_ move: Move, to board: Board) throws -> Board {
        var board = board

        switch (move.from, move.to) {

        // ----- From a free cell -----
        case let (.freeCell(i), dest):
            guard board.freeCells.indices.contains(i), let card = board.freeCells[i] else {
                throw FreeCellError.emptySource
            }
            try place(card, to: dest, in: &board)
            board.freeCells[i] = nil
            return board

        // ----- From a cascade -----
        case let (.cascade(c), dest):
            guard board.cascades.indices.contains(c), !board.cascades[c].isEmpty else {
                throw FreeCellError.emptySource
            }
            let column = board.cascades[c]

            // Single-card destinations (free cell or foundation) only ever move the top card.
            switch dest {
            case .freeCell, .foundation:
                guard let card = column.last else { throw FreeCellError.emptySource }
                try place(card, to: dest, in: &board)
                board.cascades[c].removeLast()
                return board

            case let .cascade(destCol):
                guard board.cascades.indices.contains(destCol) else {
                    throw FreeCellError.invalidDestination
                }
                if destCol == c { throw FreeCellError.illegalMove }

                let n = max(1, move.count)
                guard n <= column.count else { throw FreeCellError.illegalMove }
                let run = Array(column.suffix(n))
                guard isValidRun(run) else { throw FreeCellError.illegalMove }

                // The bottom card of the run must legally land on the destination top.
                guard let bottom = run.first else { throw FreeCellError.emptySource }
                let destTop = board.cascades[destCol].last
                guard canStack(bottom, onCascadeTop: destTop) else {
                    throw FreeCellError.invalidDestination
                }

                // Capacity check for supermove.
                let cap = maxMovable(board: board, destinationIsEmptyColumn: destTop == nil)
                guard n <= cap else { throw FreeCellError.notEnoughSpaceForSupermove }

                board.cascades[c].removeLast(n)
                board.cascades[destCol].append(contentsOf: run)
                return board
            }

        // ----- From a foundation (not allowed) -----
        case (.foundation, _):
            throw FreeCellError.invalidSource
        }
    }

    /// Place a single card onto a destination (free cell / foundation / cascade), mutating board.
    private static func place(_ card: Card, to dest: Location, in board: inout Board) throws {
        switch dest {
        case let .freeCell(j):
            guard board.freeCells.indices.contains(j) else { throw FreeCellError.invalidDestination }
            guard board.freeCells[j] == nil else { throw FreeCellError.invalidDestination }
            board.freeCells[j] = card

        case let .foundation(suit):
            guard card.suit == suit else { throw FreeCellError.invalidDestination }
            guard canPlaceOnFoundation(card, board: board) else { throw FreeCellError.invalidDestination }
            board.foundations[suit] = card.rank

        case let .cascade(destCol):
            guard board.cascades.indices.contains(destCol) else { throw FreeCellError.invalidDestination }
            guard canStack(card, onCascadeTop: board.cascades[destCol].last) else {
                throw FreeCellError.invalidDestination
            }
            board.cascades[destCol].append(card)
        }
    }

    // MARK: - Auto-collect (safe autoplay)

    /// The standard "safe" autoplay rule: a card may be auto-sent to its foundation only if
    /// it can never be needed to receive a card from the cascades. A card of rank R, color X
    /// is safe to play up when:
    ///   - it's an Ace or Two (always safe), or
    ///   - both opposite-color foundations are at least R-1, AND both same-color foundations
    ///     are at least R-2.
    /// This prevents auto-playing a card that another card might still need to stack onto.
    static func isSafeToAutoplay(_ card: Card, board: Board) -> Bool {
        guard canPlaceOnFoundation(card, board: board) else { return false }
        if card.rank <= 2 { return true }

        let oppositeSuits = Suit.allCases.filter { $0.isRed != card.isRed }
        let sameColorOther = Suit.allCases.filter { $0.isRed == card.isRed && $0 != card.suit }

        let oppositeOK = oppositeSuits.allSatisfy { board.foundationRank($0) >= card.rank - 1 }
        let sameOK = sameColorOther.allSatisfy { board.foundationRank($0) >= card.rank - 2 }
        return oppositeOK && sameOK
    }

    /// Repeatedly collect all safe cards to foundations until no more can be moved.
    /// Returns the resulting board and whether anything changed.
    static func autoCollect(_ board: Board) -> (board: Board, moved: Bool) {
        var board = board
        var movedAny = false
        var didMove = true
        while didMove {
            didMove = false

            // Free cells.
            for i in board.freeCells.indices {
                if let card = board.freeCells[i], isSafeToAutoplay(card, board: board) {
                    board.foundations[card.suit] = card.rank
                    board.freeCells[i] = nil
                    didMove = true
                    movedAny = true
                }
            }

            // Cascade tops.
            for c in board.cascades.indices {
                if let card = board.cascades[c].last, isSafeToAutoplay(card, board: board) {
                    board.foundations[card.suit] = card.rank
                    board.cascades[c].removeLast()
                    didMove = true
                    movedAny = true
                }
            }
        }
        return (board, movedAny)
    }

    // MARK: - Convenience targeting (for tap-to-move)

    /// Find the best destination for the top card of a source, preferring foundation.
    /// Used when the player taps a card hoping to "send it home".
    static func bestFoundationDestination(for card: Card, board: Board) -> Location? {
        canPlaceOnFoundation(card, board: board) ? .foundation(card.suit) : nil
    }

    /// Determine the length of the valid run ending at the top of a cascade column
    /// (i.e. how many top cards form an alternating descending sequence).
    static func movableRunLength(inCascade c: Int, board: Board) -> Int {
        guard board.cascades.indices.contains(c) else { return 0 }
        let col = board.cascades[c]
        guard !col.isEmpty else { return 0 }
        var length = 1
        var i = col.count - 1
        while i > 0 {
            let upper = col[i]
            let lower = col[i - 1]
            if upper.rank == lower.rank - 1 && upper.isRed != lower.isRed {
                length += 1
                i -= 1
            } else {
                break
            }
        }
        return length
    }
}
