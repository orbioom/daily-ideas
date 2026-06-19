import Foundation

// Pyramid layout: 7 rows, row i has i+1 cards (0-indexed)
// Card at pyramid[row][col] is covered by pyramid[row+1][col] and pyramid[row+1][col+1]
// Card is uncovered if both covering cards are removed (or it's in the last row)

enum CardLocation: Equatable {
    case pyramid(row: Int, col: Int)
    case drawPile
    case waste
    case removed
}

enum GamePhase: Equatable {
    case playing, won, lost
}

struct SavedPyramidGame: Codable {
    var pyramidCards: [[PlayingCard?]]  // nil = removed
    var drawPile: [PlayingCard]
    var wastePile: [PlayingCard]
    var score: Int
    var moves: Int
    var passesUsed: Int
    var date: Date
}

@Observable
final class PyramidGameEngine {
    // 7 rows; row 0 = apex (1 card), row 6 = base (7 cards)
    private(set) var pyramidCards: [[PlayingCard?]] = Array(repeating: [], count: 7)
    private(set) var drawPile: [PlayingCard] = []
    private(set) var wastePile: [PlayingCard] = []
    private(set) var score: Int = 0
    private(set) var moves: Int = 0
    private(set) var passesUsed: Int = 0   // how many times we've recycled waste → draw
    private(set) var phase: GamePhase = .playing
    private(set) var selectedCard: PlayingCard? = nil
    private(set) var selectedLocation: CardLocation? = nil

    // Undo stack: each entry is a snapshot of the full game state
    private var undoStack: [SavedPyramidGame] = []
    private let maxPasses = 3

    // MARK: - Setup

    func newGame(seed: UInt64? = nil) {
        var deck = PlayingCard.fullDeck()
        var rng = SplitMix64(seed: seed ?? UInt64(Date().timeIntervalSince1970 * 1000))
        for i in stride(from: deck.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            deck.swapAt(i, j)
        }
        // Deal 28 cards into pyramid (rows 0-6)
        var idx = 0
        for row in 0..<7 {
            pyramidCards[row] = Array(repeating: nil, count: row + 1)
            for col in 0...row {
                pyramidCards[row][col] = deck[idx]
                idx += 1
            }
        }
        drawPile = Array(deck[28...].reversed())  // remaining 24 cards
        wastePile = []
        score = 0
        moves = 0
        passesUsed = 0
        phase = .playing
        selectedCard = nil
        selectedLocation = nil
        undoStack = []
    }

    // MARK: - Accessors

    var wasteTop: PlayingCard? { wastePile.last }

    func isUncovered(row: Int, col: Int) -> Bool {
        guard row < 6 else { return true }
        let belowLeft = pyramidCards[row + 1][col]
        let belowRight = pyramidCards[row + 1][col + 1]
        return belowLeft == nil && belowRight == nil
    }

    // MARK: - Actions

    func drawCard() {
        guard phase == .playing else { return }
        saveSnapshot()
        if !drawPile.isEmpty {
            let card = drawPile.removeLast()
            wastePile.append(card)
            moves += 1
            deselect()
        } else if passesUsed < maxPasses - 1 {
            // Recycle waste back into draw
            drawPile = wastePile.reversed()
            wastePile = []
            passesUsed += 1
            moves += 1
            deselect()
        }
        checkWinLoss()
    }

    func tapPyramidCard(row: Int, col: Int) {
        guard phase == .playing else { return }
        guard let card = pyramidCards[row][col] else { return }
        guard isUncovered(row: row, col: col) else { return }

        if card.canRemoveAlone {
            saveSnapshot()
            pyramidCards[row][col] = nil
            score += pointsFor(rank: 13)
            moves += 1
            deselect()
            checkWinLoss()
            return
        }

        if let sel = selectedCard {
            if PlayingCard.pairSumsTo13(sel, card) {
                saveSnapshot()
                removeSelected()
                pyramidCards[row][col] = nil
                score += pointsFor(rank: card.rank)
                moves += 1
                deselect()
                checkWinLoss()
            } else {
                // Replace selection
                selectedCard = card
                selectedLocation = .pyramid(row: row, col: col)
            }
        } else {
            selectedCard = card
            selectedLocation = .pyramid(row: row, col: col)
        }
    }

    func tapWaste() {
        guard phase == .playing, let waste = wasteTop else { return }

        if waste.canRemoveAlone {
            saveSnapshot()
            wastePile.removeLast()
            score += pointsFor(rank: 13)
            moves += 1
            deselect()
            checkWinLoss()
            return
        }

        if let sel = selectedCard {
            if PlayingCard.pairSumsTo13(sel, waste) {
                saveSnapshot()
                removeSelected()
                wastePile.removeLast()
                score += pointsFor(rank: waste.rank)
                moves += 1
                deselect()
                checkWinLoss()
            } else {
                selectedCard = waste
                selectedLocation = .waste
            }
        } else {
            selectedCard = waste
            selectedLocation = .waste
        }
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        let snap = undoStack.removeLast()
        restoreSnapshot(snap)
    }

    // MARK: - Private helpers

    private func deselect() {
        selectedCard = nil
        selectedLocation = nil
    }

    private func removeSelected() {
        guard let loc = selectedLocation else { return }
        switch loc {
        case .pyramid(let r, let c):
            pyramidCards[r][c] = nil
            score += pointsFor(rank: selectedCard?.rank ?? 0)
        case .waste:
            if !wastePile.isEmpty { wastePile.removeLast() }
            score += pointsFor(rank: selectedCard?.rank ?? 0)
        default: break
        }
    }

    private func pointsFor(rank: Int) -> Int {
        switch rank {
        case 13: return 50
        case 1, 2, 3: return 30
        default: return 20
        }
    }

    private func checkWinLoss() {
        let pyramidClear = pyramidCards.allSatisfy { row in row.allSatisfy { $0 == nil } }
        if pyramidClear {
            score += 250  // bonus
            phase = .won
            return
        }
        if drawPile.isEmpty && wastePile.isEmpty { phase = .lost; return }
        if drawPile.isEmpty && passesUsed >= maxPasses - 1 && !hasAnyMove() {
            phase = .lost
        }
    }

    private func hasAnyMove() -> Bool {
        let uncoveredRanks = uncoveredPyramidCards().map { $0.rank }
        let wasteRank = wasteTop?.rank
        // Check King
        if uncoveredRanks.contains(13) || wasteRank == 13 { return true }
        // Check pairs in pyramid
        for a in uncoveredRanks {
            for b in uncoveredRanks where a + b == 13 { return true }
        }
        // Check waste vs pyramid
        if let wr = wasteRank {
            if uncoveredRanks.contains(13 - wr) { return true }
        }
        return false
    }

    private func uncoveredPyramidCards() -> [PlayingCard] {
        var result: [PlayingCard] = []
        for row in 0..<7 {
            for col in 0...row {
                if let c = pyramidCards[row][col], isUncovered(row: row, col: col) {
                    result.append(c)
                }
            }
        }
        return result
    }

    // MARK: - Snapshots

    private func saveSnapshot() {
        let snap = SavedPyramidGame(
            pyramidCards: pyramidCards,
            drawPile: drawPile,
            wastePile: wastePile,
            score: score,
            moves: moves,
            passesUsed: passesUsed,
            date: Date()
        )
        undoStack.append(snap)
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    private func restoreSnapshot(_ snap: SavedPyramidGame) {
        pyramidCards = snap.pyramidCards
        drawPile = snap.drawPile
        wastePile = snap.wastePile
        score = snap.score
        moves = snap.moves
        passesUsed = snap.passesUsed
        phase = .playing
        deselect()
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canDrawOrRecycle: Bool {
        !drawPile.isEmpty || passesUsed < maxPasses - 1
    }
    var passesRemaining: Int { max(0, maxPasses - 1 - passesUsed) }
}

// Simple LCG-based RNG seeded by date
struct SplitMix64 {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
