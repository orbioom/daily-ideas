import Foundation

/// A board coordinate. Rows and columns are 0-based.
struct Coord: Equatable, Hashable, Codable {
    let row: Int
    let col: Int
}

/// A polyomino piece: a set of relative cell offsets, a color index (1...palette.count),
/// and a stable id for SwiftUI. Offsets are normalized so the minimum row and col are 0.
struct Piece: Identifiable, Equatable, Codable {
    let id: UUID
    /// Offsets relative to an anchor (top-left). Each is (dr, dc), normalized to start at 0,0.
    let cells: [Coord]
    /// 1-based color index into the active palette.
    let colorIndex: Int

    init(id: UUID = UUID(), cells: [Coord], colorIndex: Int) {
        // Normalize so the bounding box starts at (0,0). Guard against an empty set.
        let minR = cells.map(\.row).min() ?? 0
        let minC = cells.map(\.col).min() ?? 0
        self.cells = cells.map { Coord(row: $0.row - minR, col: $0.col - minC) }
        self.colorIndex = colorIndex
        self.id = id
    }

    /// Number of filled cells (used for scoring).
    var size: Int { cells.count }

    /// Bounding-box height (rows).
    var height: Int { (cells.map(\.row).max() ?? 0) + 1 }
    /// Bounding-box width (cols).
    var width: Int { (cells.map(\.col).max() ?? 0) + 1 }
}

/// The result of placing a piece: the new grid plus what got cleared and points context.
struct PlacementResult: Equatable {
    let grid: [[Int]]
    let clearedRows: [Int]
    let clearedCols: [Int]
    let gainedCells: Int
    /// Distinct cells cleared (rows+cols minus double-counted intersections).
    let clearedCellCount: Int

    var linesCleared: Int { clearedRows.count + clearedCols.count }
}

/// The pure, deterministic block-puzzle engine. No SwiftUI, no SwiftData. Fully
/// bounds-checked: no force unwraps, no unchecked subscripts, no unguarded division.
enum BlockEngine {
    static let size = 8
    static let range = 0..<size

    // MARK: - Grid helpers

    static func emptyGrid() -> [[Int]] {
        [[Int]](repeating: [Int](repeating: 0, count: size), count: size)
    }

    /// Validate a decoded grid; returns a fresh empty grid if shape is wrong.
    static func normalized(_ grid: [[Int]]) -> [[Int]] {
        guard grid.count == size, grid.allSatisfy({ $0.count == size }) else {
            return emptyGrid()
        }
        return grid
    }

    static func inBounds(_ r: Int, _ c: Int) -> Bool {
        r >= 0 && r < size && c >= 0 && c < size
    }

    // MARK: - Placement

    /// True if every cell of `piece` placed at `anchor` is in-bounds and empty.
    static func canPlace(_ piece: Piece, atAnchor anchor: Coord, grid: [[Int]]) -> Bool {
        let g = normalized(grid)
        for cell in piece.cells {
            let r = anchor.row + cell.row
            let c = anchor.col + cell.col
            guard inBounds(r, c) else { return false }
            // Bounds already checked, so subscript is safe.
            if g[r][c] != 0 { return false }
        }
        return true
    }

    /// True if `piece` can be placed at ANY anchor on `grid`.
    static func hasAnyPlacement(_ piece: Piece, grid: [[Int]]) -> Bool {
        let g = normalized(grid)
        for r in range {
            for c in range {
                if canPlace(piece, atAnchor: Coord(row: r, col: c), grid: g) {
                    return true
                }
            }
        }
        return false
    }

    /// Place `piece` at `anchor`, then detect & clear full rows and columns.
    /// Returns the new grid and what was cleared. If placement is invalid, returns the
    /// grid unchanged with zero gains (callers should check `canPlace` first).
    static func place(_ piece: Piece, atAnchor anchor: Coord, grid: [[Int]]) -> PlacementResult {
        var g = normalized(grid)
        guard canPlace(piece, atAnchor: anchor, grid: g) else {
            return PlacementResult(grid: g, clearedRows: [], clearedCols: [],
                                   gainedCells: 0, clearedCellCount: 0)
        }

        // Write the piece.
        for cell in piece.cells {
            let r = anchor.row + cell.row
            let c = anchor.col + cell.col
            if inBounds(r, c) {
                g[r][c] = piece.colorIndex
            }
        }
        let gained = piece.cells.count

        // Detect full rows & columns BEFORE clearing (so intersections clear correctly).
        var fullRows: [Int] = []
        for r in range where g[r].allSatisfy({ $0 != 0 }) {
            fullRows.append(r)
        }
        var fullCols: [Int] = []
        for c in range {
            var full = true
            for r in range where g[r][c] == 0 { full = false; break }
            if full { fullCols.append(c) }
        }

        // Count distinct cleared cells (rows ∪ cols).
        var clearedCells = Set<Coord>()
        for r in fullRows { for c in range { clearedCells.insert(Coord(row: r, col: c)) } }
        for c in fullCols { for r in range { clearedCells.insert(Coord(row: r, col: c)) } }

        // Apply clears.
        for coord in clearedCells {
            if inBounds(coord.row, coord.col) { g[coord.row][coord.col] = 0 }
        }

        return PlacementResult(grid: g,
                               clearedRows: fullRows,
                               clearedCols: fullCols,
                               gainedCells: gained,
                               clearedCellCount: clearedCells.count)
    }

    // MARK: - Game over

    /// True if NONE of the offered pieces can be placed anywhere. An empty tray is not
    /// game over (a refill is pending), so callers pass only the currently-available pieces.
    static func isGameOver(pieces: [Piece], grid: [[Int]]) -> Bool {
        guard !pieces.isEmpty else { return false }
        for piece in pieces where hasAnyPlacement(piece, grid: grid) {
            return false
        }
        return true
    }

    // MARK: - Scoring
    //
    // Scoring is explicit and consistent:
    //   • Placing a piece earns 1 point per filled cell (`gainedCells`).
    //   • Clearing lines earns a bonus: base 10 per line, multiplied by the number of
    //     lines cleared at once (rewards simultaneous clears), multiplied by the current
    //     combo multiplier.
    //   • Combo: a streak of consecutive placements that each clear ≥1 line. The combo
    //     multiplier is `1 + max(0, combo - 1) / 2`, capped at 4×, so:
    //       combo 1 → 1.0×, combo 2 → 1.5×, combo 3 → 2.0×, … combo 7+ → 4.0×.
    //
    // Example: clearing 2 lines on a combo of 3 → 10 * 2 * 2.0 = 40 line points,
    //          plus the gained-cell points for the piece itself.

    static let comboCap = 4.0

    static func comboMultiplier(_ combo: Int) -> Double {
        guard combo > 1 else { return 1.0 }
        let m = 1.0 + Double(combo - 1) * 0.5
        return min(m, comboCap)
    }

    /// Points earned for a placement. `comboAfter` is the combo streak value AFTER this
    /// placement (i.e. 0 if no line was cleared, otherwise previousCombo + 1).
    static func points(for result: PlacementResult, comboAfter: Int) -> Int {
        var total = result.gainedCells
        let lines = result.linesCleared
        if lines > 0 {
            let base = 10 * lines * lines  // base 10 per line × number of lines (quadratic reward)
            let bonus = Double(base) * comboMultiplier(comboAfter)
            total += Int(bonus.rounded())
        }
        return total
    }
}
