import Foundation

/// A coordinate on the board.
struct Cell: Hashable, Codable {
    var row: Int
    var col: Int
}

/// A mutable 2D grid of optional gems (nil = empty cell during gravity).
/// Fully index-guarded: every accessor returns nil / no-ops on out-of-range input.
struct Board: Codable {
    let rows: Int
    let cols: Int
    private(set) var cells: [[Gem?]]

    init(rows: Int, cols: Int) {
        self.rows = max(1, rows)
        self.cols = max(1, cols)
        self.cells = Array(repeating: Array(repeating: nil, count: self.cols), count: self.rows)
    }

    func inBounds(_ r: Int, _ c: Int) -> Bool {
        r >= 0 && r < rows && c >= 0 && c < cols
    }

    func inBounds(_ cell: Cell) -> Bool { inBounds(cell.row, cell.col) }

    func gem(_ r: Int, _ c: Int) -> Gem? {
        guard inBounds(r, c) else { return nil }
        return cells[r][c]
    }

    func gem(at cell: Cell) -> Gem? { gem(cell.row, cell.col) }

    mutating func set(_ r: Int, _ c: Int, _ gem: Gem?) {
        guard inBounds(r, c) else { return }
        cells[r][c] = gem
    }

    mutating func set(_ cell: Cell, _ gem: Gem?) { set(cell.row, cell.col, gem) }

    /// True only for orthogonally adjacent, in-bounds, distinct cells.
    func areAdjacent(_ a: Cell, _ b: Cell) -> Bool {
        guard inBounds(a), inBounds(b) else { return false }
        let dr = abs(a.row - b.row)
        let dc = abs(a.col - b.col)
        return (dr + dc) == 1
    }

    mutating func swap(_ a: Cell, _ b: Cell) {
        guard inBounds(a), inBounds(b) else { return }
        let tmp = cells[a.row][a.col]
        cells[a.row][a.col] = cells[b.row][b.col]
        cells[b.row][b.col] = tmp
    }

    var allCells: [Cell] {
        var out: [Cell] = []
        out.reserveCapacity(rows * cols)
        for r in 0..<rows {
            for c in 0..<cols {
                out.append(Cell(row: r, col: c))
            }
        }
        return out
    }

    /// Count of gems of a given color currently on the board (for color-goal levels).
    func count(of color: GemColor) -> Int {
        var n = 0
        for r in 0..<rows {
            for c in 0..<cols where cells[r][c]?.color == color {
                n += 1
            }
        }
        return n
    }
}
