import Foundation

/// The library of polyomino shapes used by the dealer. Shapes are defined as relative
/// (row, col) offsets; colors are assigned at deal time. ~18 distinct shapes covering
/// monomino, dominoes, trominoes, tetrominoes (incl. square/T/L/S/I rotations), the 3×3
/// square, and long 1×4 / 1×5 bars in both orientations.
enum PieceLibrary {

    /// A named shape template (offsets only; color assigned when dealt).
    struct Shape {
        let name: String
        let cells: [Coord]
        init(_ name: String, _ pairs: [(Int, Int)]) {
            self.name = name
            self.cells = pairs.map { Coord(row: $0.0, col: $0.1) }
        }
    }

    static let shapes: [Shape] = [
        // Monomino
        Shape("dot", [(0, 0)]),
        // Dominoes
        Shape("domino-h", [(0, 0), (0, 1)]),
        Shape("domino-v", [(0, 0), (1, 0)]),
        // Trominoes
        Shape("tri-h", [(0, 0), (0, 1), (0, 2)]),
        Shape("tri-v", [(0, 0), (1, 0), (2, 0)]),
        Shape("corner-tl", [(0, 0), (0, 1), (1, 0)]),
        Shape("corner-tr", [(0, 0), (0, 1), (1, 1)]),
        Shape("corner-bl", [(0, 0), (1, 0), (1, 1)]),
        Shape("corner-br", [(0, 1), (1, 0), (1, 1)]),
        // Tetrominoes
        Shape("square", [(0, 0), (0, 1), (1, 0), (1, 1)]),
        Shape("tee", [(0, 0), (0, 1), (0, 2), (1, 1)]),
        Shape("ell", [(0, 0), (1, 0), (2, 0), (2, 1)]),
        Shape("jay", [(0, 1), (1, 1), (2, 1), (2, 0)]),
        Shape("ess", [(0, 1), (0, 2), (1, 0), (1, 1)]),
        Shape("zee", [(0, 0), (0, 1), (1, 1), (1, 2)]),
        Shape("bar4-h", [(0, 0), (0, 1), (0, 2), (0, 3)]),
        Shape("bar4-v", [(0, 0), (1, 0), (2, 0), (3, 0)]),
        // Big pieces
        Shape("bar5-h", [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)]),
        Shape("bar5-v", [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)]),
        Shape("big-square", [(0, 0), (0, 1), (0, 2),
                             (1, 0), (1, 1), (1, 2),
                             (2, 0), (2, 1), (2, 2)])
    ]

    /// A weighting that biases the deal toward small/medium pieces so the board stays
    /// playable. Index aligns with `shapes`. Larger pieces are rarer.
    static let weights: [Int] = [
        2,           // dot
        4, 4,        // dominoes
        4, 4,        // tri straight
        4, 4, 4, 4,  // corners
        5, 4, 4, 4,  // square, tee, ell, jay
        3, 3,        // ess, zee
        3, 3,        // bar4
        2, 2,        // bar5
        1            // big-square
    ]

    static let paletteColorCount = 6  // all bundled palettes ship 6 colors
}
