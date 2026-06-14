import Foundation

extension Board {
    /// Apply a move WITHOUT checking legality (used by the legality filter and search).
    /// Handles captures, en passant, castling rook movement, promotion, and all state
    /// bookkeeping (rights, en-passant target, clocks, side to move, move number).
    func applyingUnchecked(_ move: Move) -> Board {
        var sq = squares
        let fromIdx = move.from.index
        let toIdx = move.to.index
        guard (0..<64).contains(fromIdx), (0..<64).contains(toIdx),
              let moving = sq[fromIdx] else {
            // Malformed move — return self unchanged rather than crash.
            return self
        }

        let color = moving.color
        let isPawn = moving.type == .pawn
        var captured = sq[toIdx]
        var newCastling = castling
        var newEnPassant: Square? = nil

        // --- En passant capture: remove the pawn that sits beside the destination. ---
        if isPawn, let ep = enPassant, move.to == ep, sq[toIdx] == nil {
            // Captured pawn is on the destination file, on the moving pawn's *origin* rank.
            if let capSq = Square(file: move.to.file, rank: move.from.rank) {
                captured = sq[capSq.index]
                sq[capSq.index] = nil
            }
        }

        // --- Move the piece, applying promotion if requested. ---
        sq[fromIdx] = nil
        if isPawn, let promo = move.promotion {
            sq[toIdx] = Piece(color: color, type: promo)
        } else {
            sq[toIdx] = moving
        }

        // --- Castling: move the rook to its destination. ---
        if moving.type == .king, abs(move.to.file - move.from.file) == 2 {
            let rank = move.from.rank
            if move.to.file == 6 { // king-side: h-rook -> f
                if let h = Square(file: 7, rank: rank), let f = Square(file: 5, rank: rank) {
                    sq[f.index] = sq[h.index]
                    sq[h.index] = nil
                }
            } else if move.to.file == 2 { // queen-side: a-rook -> d
                if let a = Square(file: 0, rank: rank), let d = Square(file: 3, rank: rank) {
                    sq[d.index] = sq[a.index]
                    sq[a.index] = nil
                }
            }
        }

        // --- Update castling rights. ---
        // King moves: lose both rights for that color.
        if moving.type == .king {
            if color == .white { newCastling.whiteKingSide = false; newCastling.whiteQueenSide = false }
            else { newCastling.blackKingSide = false; newCastling.blackQueenSide = false }
        }
        // Rook moves from its home square: lose that side's right.
        if moving.type == .rook {
            updateRightsForRookSquare(move.from, of: color, in: &newCastling)
        }
        // Rook captured on its home square: opponent loses that right.
        if let cap = captured, cap.type == .rook {
            updateRightsForRookSquare(move.to, of: cap.color, in: &newCastling)
        }

        // --- En passant target: set only on a pawn double-push. ---
        if isPawn, abs(move.to.rank - move.from.rank) == 2 {
            let midRank = (move.to.rank + move.from.rank) / 2
            newEnPassant = Square(file: move.from.file, rank: midRank)
        }

        // --- Clocks. ---
        let resetHalfmove = isPawn || (captured != nil)
        let newHalfmove = resetHalfmove ? 0 : halfmoveClock + 1
        let newFullmove = color == .black ? fullmoveNumber + 1 : fullmoveNumber

        return Board(squares: sq,
                     sideToMove: color.opposite,
                     castling: newCastling,
                     enPassant: newEnPassant,
                     halfmoveClock: newHalfmove,
                     fullmoveNumber: newFullmove)
    }

    /// Make a move only if it is legal; returns nil otherwise. The UI-facing entry point.
    func makeMove(_ move: Move) -> Board? {
        guard isLegal(move) else { return nil }
        return applyingUnchecked(move)
    }

    private func updateRightsForRookSquare(_ sq: Square, of color: PieceColor, in rights: inout CastlingRights) {
        switch (color, sq.file, sq.rank) {
        case (.white, 0, 0): rights.whiteQueenSide = false
        case (.white, 7, 0): rights.whiteKingSide = false
        case (.black, 0, 7): rights.blackQueenSide = false
        case (.black, 7, 7): rights.blackKingSide = false
        default: break
        }
    }
}
