import Foundation

/// One deduction the line solver can make about a single cell.
struct ForcedCell: Equatable {
    let index: Int        // position within the line
    let state: CellState  // .filled or .crossed
}

/// A located hint applied to the full board (which line + the forced cell).
struct Hint: Equatable {
    enum Axis: Equatable { case row, column }
    let axis: Axis
    let line: Int      // row index or column index
    let index: Int     // position within that line
    let state: CellState
}

/// The pure nonogram logic: clue derivation, win validation, and a real line solver
/// using the leftmost/rightmost overlap method. No SwiftUI, fully testable. Every
/// array access is guarded — malformed clues or lines produce no-ops, never crashes.
enum NonogramEngine {

    // MARK: - Clue derivation

    /// Runs of consecutive `true` values in a boolean line. An all-empty line → `[0]`.
    static func clue(for line: [Bool]) -> [Int] {
        var runs: [Int] = []
        var current = 0
        for cell in line {
            if cell {
                current += 1
            } else if current > 0 {
                runs.append(current)
                current = 0
            }
        }
        if current > 0 { runs.append(current) }
        return runs.isEmpty ? [0] : runs
    }

    /// Row clues for a full solution grid (one clue list per row).
    static func rowClues(_ solution: [[Bool]]) -> [[Int]] {
        solution.map { clue(for: $0) }
    }

    /// Column clues for a full solution grid (one clue list per column).
    static func columnClues(_ solution: [[Bool]]) -> [[Int]] {
        guard let width = solution.first?.count, width > 0 else { return [] }
        var result: [[Int]] = []
        result.reserveCapacity(width)
        for c in 0..<width {
            var column: [Bool] = []
            column.reserveCapacity(solution.count)
            for row in solution {
                // Guard against ragged rows even though Puzzle guarantees rectangularity.
                column.append(c < row.count ? row[c] : false)
            }
            result.append(clue(for: column))
        }
        return result
    }

    // MARK: - Win validation

    /// True when the player's marks reproduce the solution's filled set exactly.
    /// "filled by player" must equal "filled in solution" cell-for-cell; crossed and
    /// unknown both count as "not filled". Dimensions must match.
    static func isSolved(player: [[CellState]], solution: [[Bool]]) -> Bool {
        guard player.count == solution.count, !solution.isEmpty else { return false }
        for r in 0..<solution.count {
            let solRow = solution[r]
            let playerRow = player[r]
            guard playerRow.count == solRow.count else { return false }
            for c in 0..<solRow.count {
                let playerFilled = (playerRow[c] == .filled)
                if playerFilled != solRow[c] { return false }
            }
        }
        return true
    }

    /// Count of cells the player filled that are empty in the solution (mistakes so far).
    static func mistakeCount(player: [[CellState]], solution: [[Bool]]) -> Int {
        guard player.count == solution.count else { return 0 }
        var count = 0
        for r in 0..<solution.count {
            let solRow = solution[r]
            let playerRow = player[r]
            guard playerRow.count == solRow.count else { continue }
            for c in 0..<solRow.count where playerRow[c] == .filled && !solRow[c] {
                count += 1
            }
        }
        return count
    }

    // MARK: - Line solver (placement DP)

    /// Given a single line's clue and the player's current known states, returns the
    /// cells that are *forced* — those whose value is identical across **every** valid
    /// placement of the clue consistent with the current marks. This is the engine behind
    /// Hints and the logical-solvability guarantee.
    ///
    /// Method: a placement search (memoized for feasibility) explores every legal way to
    /// lay the runs into the line, respecting the player's `.filled` (must be covered) and
    /// `.crossed` (must be a gap) marks. While walking valid placements it records, per
    /// cell, whether that cell can be filled in some placement (`canFill`) and whether it
    /// can be empty in some placement (`canEmpty`). A currently-unknown cell that can only
    /// ever be filled is a forced fill; one that can only ever be empty is a forced cross.
    /// Returns `[]` if no valid placement exists (contradictory / over-constrained input)
    /// — never crashes, never force-unwraps. Bounded by `runs.count × n`, so it always
    /// terminates.
    static func solveLine(clue: [Int], states: [CellState]) -> [ForcedCell] {
        let n = states.count
        guard n > 0 else { return [] }

        let runs = clue.filter { $0 > 0 }

        // Empty clue: the whole line must be empty.
        if runs.isEmpty {
            if states.contains(.filled) { return [] } // contradiction
            var forced: [ForcedCell] = []
            for i in 0..<n where states[i] == .unknown {
                forced.append(ForcedCell(index: i, state: .crossed))
            }
            return forced
        }

        // Quick reject: not enough room for the runs plus mandatory gaps.
        let minWidth = runs.reduce(0, +) + (runs.count - 1)
        guard minWidth <= n else { return [] }

        var solver = LineSolver(runs: runs, states: states, n: n)
        guard solver.hasAnyValidPlacement() else { return [] }
        solver.markReachable()

        var forced: [ForcedCell] = []
        for i in 0..<n where states[i] == .unknown {
            let canFill = solver.canFill[i]
            let canEmpty = solver.canEmpty[i]
            if canFill && !canEmpty {
                forced.append(ForcedCell(index: i, state: .filled))
            } else if canEmpty && !canFill {
                forced.append(ForcedCell(index: i, state: .crossed))
            }
        }
        return forced
    }

    /// Encapsulates the per-line placement DP. Value type; all indices guarded.
    private struct LineSolver {
        let runs: [Int]
        let states: [CellState]
        let n: Int
        var canFill: [Bool]
        var canEmpty: [Bool]
        /// Memo of `feasible(pos, ri)` keyed by `pos * (runs.count + 1) + ri`.
        private var feasibleMemo: [Int8]

        init(runs: [Int], states: [CellState], n: Int) {
            self.runs = runs
            self.states = states
            self.n = n
            self.canFill = [Bool](repeating: false, count: n)
            self.canEmpty = [Bool](repeating: false, count: n)
            // (n + 1) possible pos values (0...n) × (runs.count + 1) run indices.
            self.feasibleMemo = [Int8](repeating: -1, count: (n + 2) * (runs.count + 2))
        }

        mutating func hasAnyValidPlacement() -> Bool { feasible(pos: 0, ri: 0) }

        /// True if `runs[ri...]` can be placed in cells `[pos, n)` consistent with marks.
        private mutating func feasible(pos: Int, ri: Int) -> Bool {
            if pos > n { return false }
            let key = pos * (runs.count + 2) + ri
            if key >= 0 && key < feasibleMemo.count, feasibleMemo[key] != -1 {
                return feasibleMemo[key] == 1
            }
            var result = false
            if ri >= runs.count {
                // No runs left: remaining cells must contain no required fill.
                result = !rangeHasFilled(pos, n)
            } else {
                let len = runs[ri]
                var p = pos
                while p + len <= n {
                    // Any filled cell skipped before `p` can't be left uncovered.
                    if rangeHasFilled(pos, p) { break }
                    if blockClear(p, len) {
                        let after = p + len
                        let gapOK = (after == n) || (states[after] != .filled)
                        if gapOK {
                            let nextPos = (after < n) ? after + 1 : after
                            if feasible(pos: nextPos, ri: ri + 1) {
                                result = true
                                break
                            }
                        }
                    }
                    p += 1
                }
            }
            if key >= 0 && key < feasibleMemo.count { feasibleMemo[key] = result ? 1 : 0 }
            return result
        }

        /// Walks every *valid* placement (pruned by `feasible`) and marks reachable
        /// fill / empty states per cell.
        mutating func markReachable() {
            mark(pos: 0, ri: 0)
        }

        private mutating func mark(pos: Int, ri: Int) {
            if ri >= runs.count {
                if !rangeHasFilled(pos, n) {
                    for i in pos..<n { canEmpty[i] = true }
                }
                return
            }
            let len = runs[ri]
            var p = pos
            while p + len <= n {
                if rangeHasFilled(pos, p) { break }
                if blockClear(p, len) {
                    let after = p + len
                    let gapOK = (after == n) || (states[after] != .filled)
                    let nextPos = (after < n) ? after + 1 : after
                    if gapOK && feasible(pos: nextPos, ri: ri + 1) {
                        // This is a valid partial layout — mark its cells.
                        for i in pos..<p { canEmpty[i] = true }       // gap before the run
                        for i in p..<(p + len) { canFill[i] = true }  // the run itself
                        if after < n { canEmpty[after] = true }        // mandatory gap after
                        mark(pos: nextPos, ri: ri + 1)
                    }
                }
                p += 1
            }
        }

        /// True if any cell in `[lo, hi)` is marked `.filled`. Bounds-guarded.
        private func rangeHasFilled(_ lo: Int, _ hi: Int) -> Bool {
            let a = max(0, lo); let b = min(n, hi)
            guard a < b else { return false }
            for i in a..<b where states[i] == .filled { return true }
            return false
        }

        /// True if the block `[pos, pos+len)` is within bounds and contains no `.crossed`.
        private func blockClear(_ pos: Int, _ len: Int) -> Bool {
            guard pos >= 0, pos + len <= n else { return false }
            for i in pos..<(pos + len) where states[i] == .crossed { return false }
            return true
        }
    }

    // MARK: - Board-level hint

    /// Scans every row and column with the line solver and returns the first available
    /// deduction that changes an unknown cell. Returns `nil` if nothing is forced (the
    /// board may need a guess, or is already complete). Pure & guarded.
    static func nextHint(player: [[CellState]],
                         rowClues: [[Int]],
                         columnClues: [[Int]]) -> Hint? {
        let rows = player.count
        guard rows > 0 else { return nil }
        let cols = player.first?.count ?? 0
        guard cols > 0 else { return nil }

        // Rows first.
        for r in 0..<rows {
            guard r < rowClues.count else { continue }
            let line = player[r]
            guard line.count == cols else { continue }
            let forced = solveLine(clue: rowClues[r], states: line)
            if let f = forced.first {
                return Hint(axis: .row, line: r, index: f.index, state: f.state)
            }
        }

        // Then columns.
        for c in 0..<cols {
            guard c < columnClues.count else { continue }
            var line: [CellState] = []
            line.reserveCapacity(rows)
            for r in 0..<rows {
                let row = player[r]
                line.append(c < row.count ? row[c] : .unknown)
            }
            let forced = solveLine(clue: columnClues[c], states: line)
            if let f = forced.first {
                return Hint(axis: .column, line: c, index: f.index, state: f.state)
            }
        }

        return nil
    }
}
