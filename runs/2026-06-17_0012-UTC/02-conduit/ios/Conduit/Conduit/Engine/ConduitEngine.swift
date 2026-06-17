import SwiftUI
import Observation

/// The interactive game model for a single puzzle.
///
/// Holds the player's in-progress path per color and all drag handling:
///   * begin a drag on an endpoint or on the trailing end of an existing path,
///   * extend to orthogonally-adjacent empty or own cells,
///   * backtrack when dragging back over the path,
///   * auto-truncate a conflicting other-color path when entering one of its cells.
///
/// Exposes derived state used by the UI: `moveCount`, `coveragePercent`,
/// `connectedPairs`, `isSolved` (all connected AND 100% coverage), and
/// `isNearWin` (all connected but board not full).
@Observable
final class ConduitEngine {

    let puzzle: Puzzle

    /// Ordered cell list per color (the drawn pipe).
    private(set) var paths: [PipeColor: [Cell]] = [:]

    /// Move counter — increments each time the player commits a new drag stroke.
    private(set) var moveCount: Int = 0

    /// The color currently being dragged, if any.
    private(set) var activeColor: PipeColor? = nil

    /// Undo stack of full path snapshots.
    private var undoStack: [[PipeColor: [Cell]]] = []

    /// Cell -> owning color lookup, rebuilt as paths change.
    private var ownerCache: [Cell: PipeColor] = [:]

    /// Set true once a stroke actually changed something, so we count one move per stroke.
    private var strokeChanged = false

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        rebuildOwnerCache()
    }

    /// Restore a previously saved in-progress state.
    func restore(paths saved: [PipeColor: [Cell]], moves: Int) {
        paths = sanitize(saved)
        moveCount = max(0, moves)
        undoStack.removeAll()
        rebuildOwnerCache()
    }

    // MARK: - Derived state

    var size: Int { puzzle.size }

    var canUndo: Bool { !undoStack.isEmpty }

    /// Number of colors whose path runs endpoint-to-endpoint.
    var connectedPairs: Int {
        puzzle.pairs.reduce(0) { acc, pair in
            acc + (isConnected(pair) ? 1 : 0)
        }
    }

    var totalPairs: Int { puzzle.pairs.count }

    /// Count of filled (owned) cells.
    var filledCells: Int { ownerCache.count }

    /// Percent of the board covered, 0...100.
    var coveragePercent: Int {
        let total = puzzle.totalCells
        guard total > 0 else { return 0 }
        return Int((Double(filledCells) / Double(total) * 100).rounded())
    }

    /// Fully solved: every pair connected AND every cell filled.
    var isSolved: Bool {
        connectedPairs == totalPairs && filledCells == puzzle.totalCells
    }

    /// All pairs connected but the board is not 100% filled (the "near win").
    var isNearWin: Bool {
        connectedPairs == totalPairs && filledCells < puzzle.totalCells
    }

    /// Color owning a cell, if any.
    func color(at cell: Cell) -> PipeColor? { ownerCache[cell] }

    /// Whether a given color's path connects both its endpoints.
    func isConnected(_ pair: ColorPair) -> Bool {
        guard let path = paths[pair.color], path.count >= 2 else { return false }
        guard let first = path.first, let last = path.last else { return false }
        let ends = Set([pair.p1, pair.p2])
        return Set([first, last]) == ends
    }

    /// Returns the full path drawn for a color (may be empty).
    func path(for color: PipeColor) -> [Cell] { paths[color] ?? [] }

    /// Is the cell one of the puzzle's endpoint dots?
    func endpointColor(at cell: Cell) -> PipeColor? {
        for pair in puzzle.pairs where pair.p1 == cell || pair.p2 == cell {
            return pair.color
        }
        return nil
    }

    // MARK: - Drag handling

    /// Begin a stroke at `cell`. Valid if the cell is an endpoint, or the trailing
    /// (non-endpoint) end of an existing path. Returns true if a stroke started.
    @discardableResult
    func beginDrag(at cell: Cell) -> Bool {
        guard inBounds(cell) else { return false }
        strokeChanged = false

        // Starting on an endpoint dot: (re)start that color's path from this endpoint.
        if let color = endpointColor(at: cell) {
            snapshotForStroke()
            activeColor = color
            // Restart the path fresh from the tapped endpoint.
            setPath(color, to: [cell])
            return true
        }

        // Starting on the trailing end of an existing path: continue it.
        if let color = ownerCache[cell],
           let path = paths[color], path.last == cell {
            snapshotForStroke()
            activeColor = color
            return true
        }

        // Starting on a mid-path cell: truncate that path to here and continue from it.
        if let color = ownerCache[cell], let path = paths[color],
           let idx = path.firstIndex(of: cell) {
            snapshotForStroke()
            activeColor = color
            setPath(color, to: Array(path[0...idx]))
            return true
        }

        return false
    }

    /// Extend the active stroke toward `cell`. Handles backtracking and conflict erase.
    func dragMove(to cell: Cell) {
        guard let color = activeColor, inBounds(cell) else { return }
        guard var path = paths[color], let tail = path.last else { return }
        if cell == tail { return }

        // Backtracking: dragging onto the second-to-last own cell shortens the path.
        if path.count >= 2, path[safe: path.count - 2] == cell {
            path.removeLast()
            setPath(color, to: path)
            strokeChanged = true
            return
        }

        // Only step to an orthogonally-adjacent cell.
        guard cell.isAdjacent(to: tail) else { return }

        // Cannot pass through an endpoint that belongs to a different color.
        if let ep = endpointColor(at: cell), ep != color { return }

        // If the target already belongs to THIS color further back, snap back to it
        // (jumping/looping forward is not allowed; treat as backtrack to that index).
        if let existingIdx = path.firstIndex(of: cell) {
            setPath(color, to: Array(path[0...existingIdx]))
            strokeChanged = true
            return
        }

        // Entering a cell owned by ANOTHER color: truncate that color's path to just
        // before the conflict (Flow-style overwrite).
        if let other = ownerCache[cell], other != color {
            truncate(other, before: cell)
        }

        // Reaching the partner endpoint completes the connection; reaching any other
        // own endpoint is disallowed implicitly because we restart from an endpoint.
        path.append(cell)
        setPath(color, to: path)
        strokeChanged = true
    }

    /// Finish the active stroke, committing one move if anything changed.
    func endDrag() {
        if strokeChanged {
            moveCount += 1
        } else if let snap = undoStack.last, snap == paths {
            // No net change — discard the speculative snapshot we pushed at begin.
            undoStack.removeLast()
        }
        activeColor = nil
        strokeChanged = false
    }

    // MARK: - Actions

    /// Undo the most recent committed stroke.
    func undo() {
        guard let snap = undoStack.popLast() else { return }
        paths = snap
        rebuildOwnerCache()
        if moveCount > 0 { moveCount -= 1 }
    }

    /// Clear the board back to empty.
    func reset() {
        guard !paths.isEmpty || moveCount > 0 else { return }
        paths.removeAll()
        undoStack.removeAll()
        ownerCache.removeAll()
        moveCount = 0
        activeColor = nil
    }

    /// Reveal one full color path from the stored solution. Picks the first color
    /// that is not yet correctly connected; erases any cells that conflict.
    func hint() {
        guard let pair = puzzle.pairs.first(where: { !isConnected($0) })
                ?? puzzle.pairs.first else { return }
        snapshotForStroke()
        // Erase the solution cells from any other color first.
        for cell in pair.solution {
            if let other = ownerCache[cell], other != pair.color {
                truncate(other, before: cell)
            }
        }
        setPath(pair.color, to: pair.solution)
        moveCount += 1
        // The speculative snapshot becomes a real undo step; keep it.
    }

    /// A snapshot of the drawn paths suitable for persistence.
    func snapshot() -> [PipeColor: [Cell]] { paths }

    // MARK: - Internals

    private func inBounds(_ cell: Cell) -> Bool {
        cell.r >= 0 && cell.r < size && cell.c >= 0 && cell.c < size
    }

    private func setPath(_ color: PipeColor, to cells: [Cell]) {
        if cells.isEmpty {
            paths.removeValue(forKey: color)
        } else {
            paths[color] = cells
        }
        rebuildOwnerCache()
    }

    /// Truncate `color`'s path to end just before `cell` (exclusive).
    private func truncate(_ color: PipeColor, before cell: Cell) {
        guard let path = paths[color], let idx = path.firstIndex(of: cell) else { return }
        let kept = Array(path[0..<idx])
        setPath(color, to: kept)
    }

    private func snapshotForStroke() {
        undoStack.append(paths)
        // Bound the undo history so memory stays small.
        if undoStack.count > 200 { undoStack.removeFirst(undoStack.count - 200) }
    }

    private func rebuildOwnerCache() {
        var cache: [Cell: PipeColor] = [:]
        for (color, cells) in paths {
            for cell in cells where inBounds(cell) {
                cache[cell] = color
            }
        }
        ownerCache = cache
    }

    /// Validate restored paths: only keep cells in bounds and contiguous from an end.
    private func sanitize(_ saved: [PipeColor: [Cell]]) -> [PipeColor: [Cell]] {
        var out: [PipeColor: [Cell]] = [:]
        let validColors = Set(puzzle.pairs.map { $0.color })
        for (color, cells) in saved where validColors.contains(color) {
            var clean: [Cell] = []
            for cell in cells {
                guard inBounds(cell) else { break }
                if let prev = clean.last {
                    guard cell.isAdjacent(to: prev), !clean.contains(cell) else { break }
                }
                clean.append(cell)
            }
            if !clean.isEmpty { out[color] = clean }
        }
        return out
    }
}
