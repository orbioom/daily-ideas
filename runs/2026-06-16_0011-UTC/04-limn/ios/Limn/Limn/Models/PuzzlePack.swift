import Foundation

/// A themed group of puzzles of one size.
struct PuzzlePack: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    /// Grid size (square) this pack contains, e.g. 5, 10, 15.
    let size: Int
    /// True if this whole pack requires Pro.
    let requiresPro: Bool
    let puzzles: [Puzzle]
}
