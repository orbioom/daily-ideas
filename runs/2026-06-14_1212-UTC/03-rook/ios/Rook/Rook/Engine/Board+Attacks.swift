import Foundation

extension Board {
    /// Knight move offsets as (df, dr).
    static let knightDeltas: [(Int, Int)] = [
        (1, 2), (2, 1), (2, -1), (1, -2),
        (-1, -2), (-2, -1), (-2, 1), (-1, 2)
    ]
    /// King move offsets.
    static let kingDeltas: [(Int, Int)] = [
        (1, 0), (1, 1), (0, 1), (-1, 1),
        (-1, 0), (-1, -1), (0, -1), (1, -1)
    ]
    static let bishopDeltas: [(Int, Int)] = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
    static let rookDeltas: [(Int, Int)] = [(1, 0), (-1, 0), (0, 1), (0, -1)]

    /// Is `target` attacked by any piece of `color`?
    ///
    /// Note: pawn attack direction depends on the ATTACKER's color. A white pawn
    /// attacks the two squares diagonally *up* the board (toward rank 8).
    func isSquareAttacked(_ target: Square, by color: PieceColor) -> Bool {
        let tf = target.file
        let tr = target.rank

        // --- Pawn attacks ---
        // A pawn of `color` on square S attacks S + forward + sideways. So for a white
        // attacker, the attacking pawns sit one rank BELOW the target (dr = -1 from target).
        let pawnRankDir = color == .white ? -1 : 1
        for df in [-1, 1] {
            if let sq = Square(file: tf + df, rank: tr + pawnRankDir),
               let p = piece(at: sq), p.color == color, p.type == .pawn {
                return true
            }
        }

        // --- Knight attacks ---
        for (df, dr) in Board.knightDeltas {
            if let sq = Square(file: tf + df, rank: tr + dr),
               let p = piece(at: sq), p.color == color, p.type == .knight {
                return true
            }
        }

        // --- King attacks ---
        for (df, dr) in Board.kingDeltas {
            if let sq = Square(file: tf + df, rank: tr + dr),
               let p = piece(at: sq), p.color == color, p.type == .king {
                return true
            }
        }

        // --- Sliding: bishops/queens on diagonals ---
        if slidingAttack(from: target, deltas: Board.bishopDeltas, by: color,
                         types: [.bishop, .queen]) {
            return true
        }

        // --- Sliding: rooks/queens on files/ranks ---
        if slidingAttack(from: target, deltas: Board.rookDeltas, by: color,
                         types: [.rook, .queen]) {
            return true
        }

        return false
    }

    /// Walk each ray; if the first piece encountered is `color` and one of `types`, it's an attacker.
    private func slidingAttack(from target: Square,
                               deltas: [(Int, Int)],
                               by color: PieceColor,
                               types: Set<PieceType>) -> Bool {
        for (df, dr) in deltas {
            var f = target.file + df
            var r = target.rank + dr
            while let sq = Square(file: f, rank: r) {
                if let p = piece(at: sq) {
                    if p.color == color, types.contains(p.type) {
                        return true
                    }
                    break // blocked by some piece
                }
                f += df
                r += dr
            }
        }
        return false
    }

    /// Is `color`'s king currently in check?
    func kingInCheck(color: PieceColor) -> Bool {
        guard let ks = kingSquare(of: color) else { return false }
        return isSquareAttacked(ks, by: color.opposite)
    }
}
