import Foundation

/// Static evaluation: material plus piece-square tables. Returns a score in
/// centipawns from WHITE's perspective (positive = good for White).
enum Evaluation {
    // Piece-square tables, indexed for WHITE from White's point of view, where index 0
    // corresponds to a1 ... 63 to h8 (matching our Square indexing). For Black we mirror
    // vertically by flipping the rank.

    static let pawnTable: [Int] = [
         0,  0,  0,  0,  0,  0,  0,  0,
         5, 10, 10,-20,-20, 10, 10,  5,
         5, -5,-10,  0,  0,-10, -5,  5,
         0,  0,  0, 20, 20,  0,  0,  0,
         5,  5, 10, 25, 25, 10,  5,  5,
        10, 10, 20, 30, 30, 20, 10, 10,
        50, 50, 50, 50, 50, 50, 50, 50,
         0,  0,  0,  0,  0,  0,  0,  0
    ]

    static let knightTable: [Int] = [
        -50,-40,-30,-30,-30,-30,-40,-50,
        -40,-20,  0,  5,  5,  0,-20,-40,
        -30,  5, 10, 15, 15, 10,  5,-30,
        -30,  0, 15, 20, 20, 15,  0,-30,
        -30,  5, 15, 20, 20, 15,  5,-30,
        -30,  0, 10, 15, 15, 10,  0,-30,
        -40,-20,  0,  0,  0,  0,-20,-40,
        -50,-40,-30,-30,-30,-30,-40,-50
    ]

    static let bishopTable: [Int] = [
        -20,-10,-10,-10,-10,-10,-10,-20,
        -10,  5,  0,  0,  0,  0,  5,-10,
        -10, 10, 10, 10, 10, 10, 10,-10,
        -10,  0, 10, 10, 10, 10,  0,-10,
        -10,  5,  5, 10, 10,  5,  5,-10,
        -10,  0,  5, 10, 10,  5,  0,-10,
        -10,  0,  0,  0,  0,  0,  0,-10,
        -20,-10,-10,-10,-10,-10,-10,-20
    ]

    static let rookTable: [Int] = [
         0,  0,  0,  5,  5,  0,  0,  0,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
         5, 10, 10, 10, 10, 10, 10,  5,
         0,  0,  0,  0,  0,  0,  0,  0
    ]

    static let queenTable: [Int] = [
        -20,-10,-10, -5, -5,-10,-10,-20,
        -10,  0,  5,  0,  0,  0,  0,-10,
        -10,  5,  5,  5,  5,  5,  0,-10,
          0,  0,  5,  5,  5,  5,  0, -5,
         -5,  0,  5,  5,  5,  5,  0, -5,
        -10,  0,  5,  5,  5,  5,  0,-10,
        -10,  0,  0,  0,  0,  0,  0,-10,
        -20,-10,-10, -5, -5,-10,-10,-20
    ]

    static let kingTable: [Int] = [
         20, 30, 10,  0,  0, 10, 30, 20,
         20, 20,  0,  0,  0,  0, 20, 20,
        -10,-20,-20,-20,-20,-20,-20,-10,
        -20,-30,-30,-40,-40,-30,-30,-20,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30
    ]

    private static func table(for type: PieceType) -> [Int] {
        switch type {
        case .pawn: return pawnTable
        case .knight: return knightTable
        case .bishop: return bishopTable
        case .rook: return rookTable
        case .queen: return queenTable
        case .king: return kingTable
        }
    }

    /// Evaluate from White's perspective in centipawns.
    static func evaluate(_ board: Board) -> Int {
        var score = 0
        for idx in 0..<64 {
            guard let p = board.squares[idx] else { continue }
            let material = p.type.value
            // Mirror table index for Black (flip rank).
            let tableIndex: Int
            if p.color == .white {
                tableIndex = idx
            } else {
                let rank = idx / 8
                let file = idx % 8
                tableIndex = (7 - rank) * 8 + file
            }
            let table = table(for: p.type)
            let positional = (0..<64).contains(tableIndex) ? table[tableIndex] : 0
            let total = material + positional
            score += p.color == .white ? total : -total
        }
        return score
    }
}
