import SwiftUI

/// Drives a single play session of one puzzle. Pure view-state engine used with `@State`
/// (`@Observable`, never mixed with `@StateObject`/`@EnvironmentObject` on this type).
/// All board access is bounds-guarded; no force-unwraps anywhere on the play path.
@Observable
@MainActor
final class GameViewModel {
    let puzzle: Puzzle
    let rowClues: [[Int]]
    let columnClues: [[Int]]

    /// Player's current marks, `rows × cols`.
    private(set) var grid: [[CellState]]
    /// Undo history of full-grid snapshots (capped to keep memory bounded).
    private var undoStack: [[[CellState]]] = []
    private let maxUndo = 200

    private(set) var elapsedSeconds: Int = 0
    private(set) var mistakes: Int = 0
    private(set) var isSolved = false

    /// The cell most recently changed by a Hint, for a brief highlight pulse.
    var lastHintCell: (row: Int, col: Int)?

    var rows: Int { puzzle.rows }
    var cols: Int { puzzle.cols }

    init(puzzle: Puzzle,
         restoredGrid: [[CellState]]? = nil,
         elapsedSeconds: Int = 0,
         mistakes: Int = 0) {
        self.puzzle = puzzle
        self.rowClues = NonogramEngine.rowClues(puzzle.solution)
        self.columnClues = NonogramEngine.columnClues(puzzle.solution)

        if let restored = restoredGrid,
           restored.count == puzzle.rows,
           restored.first?.count == puzzle.cols {
            self.grid = restored
        } else {
            self.grid = GridCodec.blank(rows: puzzle.rows, cols: puzzle.cols)
        }
        self.elapsedSeconds = elapsedSeconds
        self.mistakes = mistakes
        self.isSolved = NonogramEngine.isSolved(player: grid, solution: puzzle.solution)
    }

    // MARK: - Bounds helpers

    func inBounds(_ r: Int, _ c: Int) -> Bool {
        r >= 0 && r < grid.count && c >= 0 && c < (grid.first?.count ?? 0)
    }

    func state(_ r: Int, _ c: Int) -> CellState {
        guard inBounds(r, c) else { return .unknown }
        return grid[r][c]
    }

    /// True when this cell is filled in the solution (for win-reveal rendering).
    func solutionFilled(_ r: Int, _ c: Int) -> Bool {
        guard r >= 0, r < puzzle.solution.count else { return false }
        let row = puzzle.solution[r]
        guard c >= 0, c < row.count else { return false }
        return row[c]
    }

    // MARK: - Player actions

    /// Applies a tap with the active mode. Returns the resulting state of the cell,
    /// or `nil` if the action was a no-op (out of bounds or already solved).
    @discardableResult
    func tap(_ r: Int, _ c: Int, mode: TapMode, assist: Bool) -> CellState? {
        guard !isSolved, inBounds(r, c) else { return nil }
        let current = grid[r][c]
        let target: CellState
        switch mode {
        case .fill:
            target = (current == .filled) ? .unknown : .filled
        case .cross:
            target = (current == .crossed) ? .unknown : .crossed
        }
        return setCell(r, c, to: target, assist: assist)
    }

    /// Sets a specific cell, pushing an undo snapshot. Recomputes mistakes & win.
    @discardableResult
    func setCell(_ r: Int, _ c: Int, to target: CellState, assist: Bool) -> CellState? {
        guard !isSolved, inBounds(r, c) else { return nil }
        guard grid[r][c] != target else { return grid[r][c] }
        pushUndo()
        grid[r][c] = target
        recomputeDerived(assist: assist)
        return target
    }

    /// Crosses every still-unknown cell in any row or column whose clue is fully
    /// satisfied by the player's current fills. Called after a fill when the setting is on.
    func autoCrossCompletedLines() {
        var changed = false
        // Rows.
        for r in 0..<grid.count {
            if lineIsComplete(rowClue: rowClues[safe: r], states: grid[r]) {
                for c in 0..<grid[r].count where grid[r][c] == .unknown {
                    grid[r][c] = .crossed
                    changed = true
                }
            }
        }
        // Columns.
        let width = grid.first?.count ?? 0
        for c in 0..<width {
            var col: [CellState] = []
            for r in 0..<grid.count { col.append(grid[r][c]) }
            if lineIsComplete(rowClue: columnClues[safe: c], states: col) {
                for r in 0..<grid.count where grid[r][c] == .unknown {
                    grid[r][c] = .crossed
                    changed = true
                }
            }
        }
        if changed { recomputeDerived(assist: false) }
    }

    /// True when the filled runs already present exactly match the clue (line is done).
    private func lineIsComplete(rowClue: [Int]?, states: [CellState]) -> Bool {
        guard let clue = rowClue else { return false }
        let filledRuns = NonogramEngine.clue(for: states.map { $0 == .filled })
        let normalizedClue = clue.filter { $0 > 0 }
        let normalizedFilled = filledRuns.filter { $0 > 0 }
        return normalizedFilled == normalizedClue && !normalizedClue.isEmpty
    }

    // MARK: - Hint

    /// Result of asking for a hint.
    enum HintResult: Equatable {
        case applied(row: Int, col: Int, state: CellState)
        case nothingForced
        case alreadySolved
    }

    /// Applies one logically-forced deduction from the line solver, if any.
    func applyHint() -> HintResult {
        guard !isSolved else { return .alreadySolved }
        guard let hint = NonogramEngine.nextHint(player: grid,
                                                 rowClues: rowClues,
                                                 columnClues: columnClues) else {
            return .nothingForced
        }
        let (r, c): (Int, Int)
        switch hint.axis {
        case .row: (r, c) = (hint.line, hint.index)
        case .column: (r, c) = (hint.index, hint.line)
        }
        guard inBounds(r, c) else { return .nothingForced }
        pushUndo()
        grid[r][c] = hint.state
        lastHintCell = (r, c)
        recomputeDerived(assist: false)
        return .applied(row: r, col: c, state: hint.state)
    }

    // MARK: - Undo / restart

    var canUndo: Bool { !undoStack.isEmpty }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        grid = previous
        recomputeDerived(assist: false)
    }

    func restart() {
        pushUndo()
        grid = GridCodec.blank(rows: rows, cols: cols)
        mistakes = 0
        isSolved = false
        lastHintCell = nil
    }

    // MARK: - Timer

    func tick() {
        guard !isSolved else { return }
        elapsedSeconds += 1
    }

    var timeLabel: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Persistence helpers

    var encodedGrid: String { GridCodec.encode(grid) }

    /// Fraction of solution cells correctly filled, 0...1 (for progress UI).
    var progress: Double {
        let total = puzzle.fillCount
        guard total > 0 else { return 0 }
        var correct = 0
        for r in 0..<grid.count {
            for c in 0..<grid[r].count where grid[r][c] == .filled && solutionFilled(r, c) {
                correct += 1
            }
        }
        return min(1, Double(correct) / Double(total))
    }

    // MARK: - Internals

    private func pushUndo() {
        undoStack.append(grid)
        if undoStack.count > maxUndo { undoStack.removeFirst(undoStack.count - maxUndo) }
    }

    private func recomputeDerived(assist: Bool) {
        if assist {
            mistakes = NonogramEngine.mistakeCount(player: grid, solution: puzzle.solution)
        }
        isSolved = NonogramEngine.isSolved(player: grid, solution: puzzle.solution)
    }
}

/// Safe array subscript used for clue lookups.
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
