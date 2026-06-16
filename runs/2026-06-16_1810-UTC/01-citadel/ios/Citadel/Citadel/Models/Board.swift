import Foundation

/// The full FreeCell board state. A pure value type, fully Codable so it can be
/// snapshotted for undo and encoded into SwiftData as `Data`.
struct Board: Codable, Equatable {
    /// Eight cascade columns, each a stack of cards (bottom-first, top is last element).
    var cascades: [[Card]]
    /// Four free cells, each holding zero or one card.
    var freeCells: [Card?]
    /// Top rank reached per suit on the foundations. 0 = empty, 13 = complete.
    var foundations: [Suit: Int]

    static let cascadeCount = 8
    static let freeCellCount = 4

    init(cascades: [[Card]] = Array(repeating: [], count: Board.cascadeCount),
         freeCells: [Card?] = Array(repeating: nil, count: Board.freeCellCount),
         foundations: [Suit: Int] = [:]) {
        self.cascades = cascades
        self.freeCells = freeCells
        // Always normalize foundations so every suit has an explicit entry.
        var f = foundations
        for suit in Suit.allCases where f[suit] == nil {
            f[suit] = 0
        }
        self.foundations = f
    }

    /// Number of currently empty free cells.
    var freeFreeCellCount: Int {
        freeCells.reduce(0) { $0 + ($1 == nil ? 1 : 0) }
    }

    /// Number of empty cascade columns.
    var emptyCascadeCount: Int {
        cascades.reduce(0) { $0 + ($1.isEmpty ? 1 : 0) }
    }

    /// Top rank on the foundation for a suit (0 if empty). Safe against missing keys.
    func foundationRank(_ suit: Suit) -> Int {
        foundations[suit] ?? 0
    }

    /// True when every foundation has reached the King.
    var isWon: Bool {
        Suit.allCases.allSatisfy { foundationRank($0) == 13 }
    }

    /// Total cards currently sitting on foundations (used for progress + stats).
    var foundationCardCount: Int {
        Suit.allCases.reduce(0) { $0 + foundationRank($1) }
    }
}
