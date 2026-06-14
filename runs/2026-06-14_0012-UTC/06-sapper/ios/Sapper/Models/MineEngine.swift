import Foundation

/// The result of resolving a tap/chord on the board.
enum MoveOutcome: Equatable {
    case ok
    case won
    case lost
}

/// Pure Minesweeper engine — no SwiftUI, fully deterministic given a seed and the
/// first click. Owns the grid of `Cell` values and all rules: first-click-safe
/// generation, flood fill, win/loss detection, chording, flagging.
struct MineEngine: Codable, Equatable {
    private(set) var rows: Int
    private(set) var cols: Int
    private(set) var mineCount: Int
    private(set) var cells: [Cell]
    private(set) var minesPlaced: Bool
    private(set) var isOver: Bool
    private(set) var didWin: Bool
    /// Whether this board was generated to be solvable without guessing.
    private(set) var noGuess: Bool

    // MARK: - Lifecycle

    init(rows: Int, cols: Int, mines: Int, noGuess: Bool = false) {
        let r = max(1, rows)
        let c = max(1, cols)
        self.rows = r
        self.cols = c
        self.mineCount = max(0, min(mines, max(0, r * c - 1)))
        self.cells = Array(repeating: Cell(), count: r * c)
        self.minesPlaced = false
        self.isOver = false
        self.didWin = false
        self.noGuess = noGuess
    }

    // MARK: - Indexing helpers

    func inBounds(_ row: Int, _ col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < cols
    }

    func index(_ row: Int, _ col: Int) -> Int {
        row * cols + col
    }

    /// Safe accessor: returns nil if out of range. Avoids unchecked indexing.
    func cell(at row: Int, _ col: Int) -> Cell? {
        guard inBounds(row, col) else { return nil }
        return cells[index(row, col)]
    }

    /// The 8 neighbor indices of a cell (in-bounds only).
    func neighborIndices(of i: Int) -> [Int] {
        guard i >= 0 && i < cells.count else { return [] }
        let row = i / cols
        let col = i % cols
        var result: [Int] = []
        result.reserveCapacity(8)
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let nr = row + dr
                let nc = col + dc
                if inBounds(nr, nc) { result.append(index(nr, nc)) }
            }
        }
        return result
    }

    // MARK: - Derived state

    var flagCount: Int { cells.filter { $0.state == .flagged }.count }

    /// Remaining mines = total mines minus flags placed (can go negative if the
    /// player over-flags; callers clamp for display).
    var minesRemaining: Int { mineCount - flagCount }

    var revealedCount: Int { cells.filter { $0.state == .revealed }.count }

    /// Win condition: every non-mine cell is revealed.
    var allSafeRevealed: Bool {
        for cell in cells where !cell.hasMine && cell.state != .revealed {
            return false
        }
        return true
    }

    // MARK: - Generation (first-click-safe, seedable)

    /// Place mines after the first tap, excluding the tapped cell and its 8
    /// neighbors, then compute adjacency. Deterministic given `rng`.
    mutating func placeMines(firstTap i: Int, using rng: inout SplitMix64) {
        guard i >= 0 && i < cells.count else { return }
        var forbidden = Set<Int>()
        forbidden.insert(i)
        for n in neighborIndices(of: i) { forbidden.insert(n) }

        var candidates: [Int] = []
        candidates.reserveCapacity(cells.count)
        for idx in 0..<cells.count where !forbidden.contains(idx) {
            candidates.append(idx)
        }

        // Clamp mine count to what the candidate pool can hold.
        let placeable = min(mineCount, candidates.count)
        // Partial Fisher–Yates: shuffle the first `placeable` slots.
        if placeable > 0 && candidates.count > 1 {
            for k in 0..<placeable {
                let span = candidates.count - k
                let j = k + Int(rng.next() % UInt64(span))
                candidates.swapAt(k, j)
            }
        }
        for k in 0..<placeable {
            cells[candidates[k]].hasMine = true
        }
        mineCount = placeable
        recomputeAdjacency()
        minesPlaced = true
    }

    /// Replace the entire mine layout from a precomputed set (used by the
    /// no-guess generator which validates candidate layouts before committing).
    mutating func setMineLayout(_ mineIndices: Set<Int>) {
        for idx in cells.indices { cells[idx].hasMine = false }
        for idx in mineIndices where idx >= 0 && idx < cells.count {
            cells[idx].hasMine = true
        }
        mineCount = mineIndices.count
        recomputeAdjacency()
        minesPlaced = true
    }

    private mutating func recomputeAdjacency() {
        for idx in cells.indices {
            if cells[idx].hasMine {
                cells[idx].adjacent = 0
                continue
            }
            var count = 0
            for n in neighborIndices(of: idx) where cells[n].hasMine { count += 1 }
            cells[idx].adjacent = count
        }
    }

    // MARK: - Moves

    /// Reveal a cell. If it is a mine → loss. If it is a 0, flood-fill outward.
    @discardableResult
    mutating func reveal(_ i: Int) -> MoveOutcome {
        guard !isOver, i >= 0, i < cells.count else { return .ok }
        let c = cells[i]
        guard c.state == .hidden || c.state == .questioned else { return .ok }

        if c.hasMine {
            cells[i].state = .revealed
            cells[i].detonated = true
            loseReveal()
            return .lost
        }

        floodReveal(from: i)

        if allSafeRevealed {
            winReveal()
            return .won
        }
        return .ok
    }

    /// Iterative flood fill (explicit stack — never deep recursion).
    private mutating func floodReveal(from start: Int) {
        var stack: [Int] = [start]
        while let i = stack.popLast() {
            guard i >= 0 && i < cells.count else { continue }
            let c = cells[i]
            if c.state == .revealed { continue }
            if c.state == .flagged { continue }
            if c.hasMine { continue }
            cells[i].state = .revealed
            if c.adjacent == 0 {
                for n in neighborIndices(of: i) {
                    let nc = cells[n]
                    if nc.state == .hidden || nc.state == .questioned {
                        if !nc.hasMine { stack.append(n) }
                    }
                }
            }
        }
    }

    /// Cycle a cell's mark. With question marks enabled:
    /// hidden → flagged → questioned → hidden. Otherwise hidden → flagged → hidden.
    mutating func cycleFlag(_ i: Int, allowQuestion: Bool) {
        guard !isOver, i >= 0, i < cells.count else { return }
        switch cells[i].state {
        case .hidden:
            cells[i].state = .flagged
        case .flagged:
            cells[i].state = allowQuestion ? .questioned : .hidden
        case .questioned:
            cells[i].state = .hidden
        case .revealed:
            break
        }
    }

    /// Chording: on a revealed number whose flagged-neighbor count equals its
    /// value, reveal all other (non-flagged) neighbors at once.
    @discardableResult
    mutating func chord(_ i: Int) -> MoveOutcome {
        guard !isOver, i >= 0, i < cells.count else { return .ok }
        let c = cells[i]
        guard c.state == .revealed, c.adjacent > 0 else { return .ok }

        let neighbors = neighborIndices(of: i)
        let flagged = neighbors.filter { cells[$0].state == .flagged }.count
        guard flagged == c.adjacent else { return .ok }

        var outcome: MoveOutcome = .ok
        for n in neighbors {
            let nc = cells[n]
            if nc.state == .hidden || nc.state == .questioned {
                let r = reveal(n)
                if r == .lost { outcome = .lost }
                if r == .won && outcome != .lost { outcome = .won }
            }
            if outcome == .lost { break }
        }
        return outcome
    }

    // MARK: - End-of-game reveals

    private mutating func loseReveal() {
        isOver = true
        didWin = false
        for idx in cells.indices {
            if cells[idx].hasMine {
                // Reveal unflagged mines.
                if cells[idx].state != .flagged && cells[idx].state != .revealed {
                    cells[idx].state = .revealed
                }
            } else if cells[idx].state == .flagged {
                // Mark flags placed on non-mines as wrong.
                cells[idx].wrongFlag = true
            }
        }
    }

    private mutating func winReveal() {
        isOver = true
        didWin = true
        // On a win, auto-flag every remaining mine for a satisfying finish.
        for idx in cells.indices where cells[idx].hasMine && cells[idx].state != .flagged {
            cells[idx].state = .flagged
        }
    }
}
