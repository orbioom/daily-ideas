import Foundation

/// A single nonogram puzzle: a solution grid plus the picture it depicts.
/// The solution is stored as `[String]` rows of "#" (filled) and "." (empty).
/// Construction validates the grid; an invalid grid collapses to a safe 1×1 so the
/// app can never index out of bounds at runtime.
struct Puzzle: Identifiable, Equatable, Hashable {
    /// Stable identifier from the bank (e.g. "beg-heart").
    let id: String
    /// Display name of the depicted picture.
    let name: String
    /// SF Symbol shown as a hint/thumbnail garnish in the library.
    let symbol: String
    /// The pack this puzzle belongs to.
    let packID: String
    /// rows × cols boolean solution grid; `true` = filled.
    let solution: [[Bool]]

    var rows: Int { solution.count }
    var cols: Int { solution.first?.count ?? 0 }

    /// Number of filled cells in the solution.
    var fillCount: Int {
        solution.reduce(0) { acc, row in acc + row.reduce(0) { $0 + ($1 ? 1 : 0) } }
    }

    /// A short "5 × 5" style size label.
    var sizeLabel: String { "\(rows) × \(cols)" }

    /// Builds a puzzle from "#"/"." rows. Returns a guaranteed-rectangular,
    /// non-empty grid. Malformed input (ragged or empty) falls back to a 1×1 empty
    /// grid rather than producing an unsafe model.
    init(id: String, name: String, symbol: String, packID: String, rows rowStrings: [String]) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.packID = packID
        self.solution = Puzzle.parse(rowStrings)
    }

    /// Parses and validates rows. All rows must be non-empty and the same length.
    static func parse(_ rowStrings: [String]) -> [[Bool]] {
        guard let first = rowStrings.first, !first.isEmpty else {
            return [[false]]
        }
        let width = first.count
        var grid: [[Bool]] = []
        grid.reserveCapacity(rowStrings.count)
        for line in rowStrings {
            guard line.count == width else {
                // Ragged input is invalid — fall back to a safe minimal grid.
                return [[false]]
            }
            grid.append(line.map { $0 == "#" })
        }
        return grid
    }

    /// True if the grid is rectangular, non-empty, and has at least one filled cell.
    var isValid: Bool {
        guard rows > 0, cols > 0 else { return false }
        for row in solution where row.count != cols { return false }
        return fillCount > 0
    }
}
