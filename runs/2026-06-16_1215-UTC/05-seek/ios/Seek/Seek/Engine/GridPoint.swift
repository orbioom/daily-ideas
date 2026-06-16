import Foundation

/// A cell coordinate in the word-search grid (row, col).
struct GridPoint: Hashable, Codable {
    let row: Int
    let col: Int

    init(_ row: Int, _ col: Int) {
        self.row = row
        self.col = col
    }
}

/// The eight directions a word may run in.
struct Direction: Hashable {
    let dRow: Int
    let dCol: Int

    /// All eight compass directions (orthogonal + diagonal, forward + reverse).
    static let all: [Direction] = [
        Direction(dRow: 0, dCol: 1),   // east
        Direction(dRow: 0, dCol: -1),  // west
        Direction(dRow: 1, dCol: 0),   // south
        Direction(dRow: -1, dCol: 0),  // north
        Direction(dRow: 1, dCol: 1),   // southeast
        Direction(dRow: -1, dCol: -1), // northwest
        Direction(dRow: 1, dCol: -1),  // southwest
        Direction(dRow: -1, dCol: 1)   // northeast
    ]

    var isDiagonal: Bool { dRow != 0 && dCol != 0 }
    var isReverse: Bool { dCol < 0 || (dCol == 0 && dRow < 0) }
}
