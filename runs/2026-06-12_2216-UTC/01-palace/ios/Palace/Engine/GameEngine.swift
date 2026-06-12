import Foundation
import Observation

/// Where a tapped card lives on the board.
enum BoardLocation: Equatable {
    case waste
    case foundation(Int)
    case tableau(column: Int, index: Int)
}

/// Result of a finished game, handed to the UI so it can persist a GameRecord.
struct FinishedGame: Equatable {
    var won: Bool
    var score: Int
    var moves: Int
    var durationSeconds: Int
    var drawThree: Bool
}

/// Pure Klondike rules + scoring + undo. The UI owns persistence.
@Observable
@MainActor
final class GameEngine {
    private(set) var state: GameState
    private(set) var undoStack: [GameState] = []
    /// Set when a game ends (win or abandon); the UI consumes it into SwiftData.
    var pendingRecord: FinishedGame?
    /// Card ids that should briefly shake because a tap had no legal move.
    private(set) var rejectedCardID: UUID?
    private(set) var isAutoCompleting = false
    /// Timer bookkeeping: seconds banked in `state`, plus a live segment.
    private(set) var runningSince: Date?

    var canUndo: Bool { !undoStack.isEmpty && !isAutoCompleting }
    var isWon: Bool { state.isWon }

    init(state: GameState? = nil, drawThree: Bool = false) {
        self.state = state ?? GameState.newDeal(drawThree: drawThree)
    }

    // MARK: - Timer

    func resumeClock() {
        guard !isWon, runningSince == nil else { return }
        runningSince = .now
    }

    func pauseClock() {
        if let since = runningSince {
            state.accumulatedSeconds += Date.now.timeIntervalSince(since)
            runningSince = nil
        }
    }

    func elapsedSeconds(at date: Date = .now) -> Int {
        var total = state.accumulatedSeconds
        if let since = runningSince {
            total += date.timeIntervalSince(since)
        }
        return max(0, Int(total))
    }

    // MARK: - Game lifecycle

    /// Starts a new deal. If the current game has progress, reports it as a loss first.
    func newGame(drawThree: Bool) {
        pauseClock()
        if state.moves > 0 && !state.isWon {
            pendingRecord = FinishedGame(
                won: false,
                score: state.score,
                moves: state.moves,
                durationSeconds: elapsedSeconds(),
                drawThree: state.drawThree
            )
        }
        state = GameState.newDeal(drawThree: drawThree)
        undoStack = []
        isAutoCompleting = false
        runningSince = nil
    }

    func restore(_ saved: GameState) {
        state = saved
        undoStack = []
        runningSince = nil
    }

    // MARK: - Moves

    private func pushUndo() {
        undoStack.append(state)
        if undoStack.count > 200 { undoStack.removeFirst() }
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        let clock = state.accumulatedSeconds
        state = previous
        state.accumulatedSeconds = clock   // never rewind the clock
    }

    /// Tap on the stock: draw 1 or 3, or recycle the waste when the stock is out.
    func tapStock() {
        guard !isAutoCompleting else { return }
        resumeClock()
        pushUndo()
        if state.stock.isEmpty {
            guard !state.waste.isEmpty else { undoStack.removeLast(); return }
            state.stock = state.waste.reversed().map { card in
                var c = card
                c.faceUp = false
                return c
            }
            state.waste = []
            state.recycles += 1
            if !state.drawThree {
                // Standard scoring penalizes recycling in draw-one.
                state.score = max(0, state.score - 100)
            }
            state.moves += 1
        } else {
            let count = state.drawThree ? min(3, state.stock.count) : 1
            for _ in 0..<count {
                var card = state.stock.removeLast()
                card.faceUp = true
                state.waste.append(card)
            }
            state.moves += 1
        }
    }

    /// Smart tap: move the tapped card (and any cards stacked on it) to the best
    /// legal destination — foundation first, then tableau. Returns false if no move.
    @discardableResult
    func smartMove(from location: BoardLocation) -> Bool {
        guard !isAutoCompleting else { return false }
        resumeClock()
        switch location {
        case .waste:
            guard let card = state.waste.last else { return false }
            if let f = foundationIndex(accepting: card) {
                pushUndo()
                state.waste.removeLast()
                state.foundations[f].append(card)
                state.score += 10
                state.moves += 1
                finishIfWon()
                return true
            }
            if let target = tableauTarget(for: [card]) {
                pushUndo()
                state.waste.removeLast()
                state.tableau[target].append(card)
                state.score += 5
                state.moves += 1
                return true
            }
        case .foundation(let f):
            guard let card = state.foundations[f].last else { return false }
            if let target = tableauTarget(for: [card]) {
                pushUndo()
                state.foundations[f].removeLast()
                state.tableau[target].append(card)
                state.score = max(0, state.score - 15)
                state.moves += 1
                return true
            }
        case .tableau(let column, let index):
            let pile = state.tableau[column]
            guard index < pile.count, pile[index].faceUp else { return false }
            let substack = Array(pile[index...])
            if substack.count == 1, let f = foundationIndex(accepting: substack[0]) {
                pushUndo()
                state.tableau[column].removeLast()
                state.foundations[f].append(substack[0])
                state.score += 10
                flipExposedCard(in: column)
                state.moves += 1
                finishIfWon()
                return true
            }
            if let target = tableauTarget(for: substack, excluding: column) {
                pushUndo()
                state.tableau[column].removeSubrange(index...)
                state.tableau[target].append(contentsOf: substack)
                flipExposedCard(in: column)
                state.moves += 1
                return true
            }
        }
        rejectedCardID = tappedCardID(at: location)
        return false
    }

    func clearRejection() { rejectedCardID = nil }

    private func tappedCardID(at location: BoardLocation) -> UUID? {
        switch location {
        case .waste: return state.waste.last?.id
        case .foundation(let f): return state.foundations[f].last?.id
        case .tableau(let column, let index):
            let pile = state.tableau[column]
            return index < pile.count ? pile[index].id : nil
        }
    }

    private func flipExposedCard(in column: Int) {
        guard let last = state.tableau[column].indices.last,
              !state.tableau[column][last].faceUp else { return }
        state.tableau[column][last].faceUp = true
        state.score += 5
    }

    /// First foundation pile that can accept `card` (same suit ascending from ace).
    private func foundationIndex(accepting card: Card) -> Int? {
        for (i, pile) in state.foundations.enumerated() {
            if let top = pile.last {
                if top.suit == card.suit && card.rank.rawValue == top.rank.rawValue + 1 {
                    return i
                }
            } else if card.rank == .ace {
                return i
            }
        }
        return nil
    }

    /// Best tableau column that can accept a run starting with `cards[0]`.
    /// Prefers a non-empty pile; uses an empty column only for kings (and not a
    /// pointless king shuffle from the bottom of an otherwise-empty run).
    private func tableauTarget(for cards: [Card], excluding source: Int? = nil) -> Int? {
        guard let lead = cards.first else { return nil }
        var emptyColumn: Int?
        for (i, pile) in state.tableau.enumerated() {
            if i == source { continue }
            if let top = pile.last {
                if top.faceUp && top.isRed != lead.isRed && top.rank.rawValue == lead.rank.rawValue + 1 {
                    return i
                }
            } else if lead.rank == .king, emptyColumn == nil {
                // Moving a king that already heads its own column is a no-op.
                if let source, state.tableau[source].first?.id == lead.id { continue }
                emptyColumn = i
            }
        }
        return emptyColumn
    }

    private func finishIfWon() {
        guard state.isWon else { return }
        pauseClock()
        pendingRecord = FinishedGame(
            won: true,
            score: state.score,
            moves: state.moves,
            durationSeconds: elapsedSeconds(),
            drawThree: state.drawThree
        )
    }

    // MARK: - Auto-complete

    /// True when the rest of the game is a formality: nothing hidden anywhere.
    var canAutoComplete: Bool {
        !isWon && state.stock.isEmpty && state.waste.isEmpty &&
        state.tableau.allSatisfy { pile in pile.allSatisfy(\.faceUp) }
    }

    func autoComplete() async {
        guard canAutoComplete, !isAutoCompleting else { return }
        isAutoCompleting = true
        defer { isAutoCompleting = false }
        var safety = 0
        while !state.isWon && safety < 200 {
            safety += 1
            var movedSomething = false
            // Always play the lowest-rank movable card for a natural cascade.
            var best: (column: Int, rank: Int)?
            for (i, pile) in state.tableau.enumerated() {
                guard let top = pile.last, foundationIndex(accepting: top) != nil else { continue }
                if best == nil || top.rank.rawValue < best!.rank {
                    best = (i, top.rank.rawValue)
                }
            }
            if let best, let card = state.tableau[best.column].last,
               let f = foundationIndex(accepting: card) {
                state.tableau[best.column].removeLast()
                state.foundations[f].append(card)
                state.score += 10
                state.moves += 1
                movedSomething = true
            }
            guard movedSomething else { break }
            finishIfWon()
            try? await Task.sleep(nanoseconds: 140_000_000)
        }
    }
}
