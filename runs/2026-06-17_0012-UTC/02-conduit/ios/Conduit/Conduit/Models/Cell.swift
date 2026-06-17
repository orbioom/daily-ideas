import Foundation

/// A grid coordinate. `r` = row (top to bottom), `c` = column (left to right).
/// Hashable + Codable so it can key dictionaries and serialize to a saved board.
struct Cell: Hashable, Codable, Sendable {
    var r: Int
    var c: Int

    init(_ r: Int, _ c: Int) {
        self.r = r
        self.c = c
    }

    /// Orthogonal (4-directional) adjacency.
    func isAdjacent(to other: Cell) -> Bool {
        let dr = abs(r - other.r)
        let dc = abs(c - other.c)
        return dr + dc == 1
    }

    static func == (lhs: Cell, rhs: Cell) -> Bool {
        lhs.r == rhs.r && lhs.c == rhs.c
    }
}
