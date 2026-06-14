import Foundation

extension Board {
    // MARK: - Legal moves

    /// All fully-legal moves for the side to move.
    func legalMoves() -> [Move] {
        let side = sideToMove
        var result: [Move] = []
        for move in pseudoLegalMoves() {
            let next = applyingUnchecked(move)
            // After making the move, the mover's own king must not be attacked.
            if !next.kingInCheck(color: side) {
                result.append(move)
            }
        }
        return result
    }

    /// Legal moves originating from a particular square (for the UI).
    func legalMoves(from square: Square) -> [Move] {
        legalMoves().filter { $0.from == square }
    }

    /// Is `move` a legal move in this position?
    func isLegal(_ move: Move) -> Bool {
        legalMoves().contains(move)
    }

    // MARK: - Pseudo-legal generation

    /// Pseudo-legal moves: geometrically valid, but may leave own king in check.
    func pseudoLegalMoves() -> [Move] {
        var moves: [Move] = []
        let side = sideToMove
        for idx in 0..<64 {
            guard let piece = squares[idx], piece.color == side else { continue }
            guard let from = Square(index: idx) else { continue }
            switch piece.type {
            case .pawn:   appendPawnMoves(from: from, color: side, into: &moves)
            case .knight: appendStepMoves(from: from, color: side, deltas: Board.knightDeltas, into: &moves)
            case .king:   appendStepMoves(from: from, color: side, deltas: Board.kingDeltas, into: &moves)
            case .bishop: appendSlideMoves(from: from, color: side, deltas: Board.bishopDeltas, into: &moves)
            case .rook:   appendSlideMoves(from: from, color: side, deltas: Board.rookDeltas, into: &moves)
            case .queen:
                appendSlideMoves(from: from, color: side, deltas: Board.bishopDeltas, into: &moves)
                appendSlideMoves(from: from, color: side, deltas: Board.rookDeltas, into: &moves)
            }
        }
        appendCastlingMoves(color: side, into: &moves)
        return moves
    }

    // MARK: - Per-piece generators

    /// Single-step pieces (knight, king): land on empty or enemy-occupied squares.
    private func appendStepMoves(from: Square, color: PieceColor,
                                 deltas: [(Int, Int)], into moves: inout [Move]) {
        for (df, dr) in deltas {
            guard let to = Square(file: from.file + df, rank: from.rank + dr) else { continue }
            if let occupant = piece(at: to) {
                if occupant.color != color { moves.append(Move(from: from, to: to)) }
            } else {
                moves.append(Move(from: from, to: to))
            }
        }
    }

    /// Sliding pieces (bishop, rook, queen): ray-walk until blocked.
    private func appendSlideMoves(from: Square, color: PieceColor,
                                  deltas: [(Int, Int)], into moves: inout [Move]) {
        for (df, dr) in deltas {
            var f = from.file + df
            var r = from.rank + dr
            while let to = Square(file: f, rank: r) {
                if let occupant = piece(at: to) {
                    if occupant.color != color { moves.append(Move(from: from, to: to)) }
                    break
                }
                moves.append(Move(from: from, to: to))
                f += df
                r += dr
            }
        }
    }

    /// Pawn pushes, double-push, captures, en passant and promotions.
    private func appendPawnMoves(from: Square, color: PieceColor, into moves: inout [Move]) {
        let dir = color == .white ? 1 : -1
        let startRank = color == .white ? 1 : 6
        let promoRank = color == .white ? 7 : 0

        // Single push.
        if let one = Square(file: from.file, rank: from.rank + dir), piece(at: one) == nil {
            appendPawnDestination(from: from, to: one, promoRank: promoRank, into: &moves)
            // Double push (only from start rank, both squares empty).
            if from.rank == startRank,
               let two = Square(file: from.file, rank: from.rank + 2 * dir),
               piece(at: two) == nil {
                moves.append(Move(from: from, to: two))
            }
        }

        // Captures (incl. promotion captures).
        for df in [-1, 1] {
            guard let to = Square(file: from.file + df, rank: from.rank + dir) else { continue }
            if let occupant = piece(at: to), occupant.color != color {
                appendPawnDestination(from: from, to: to, promoRank: promoRank, into: &moves)
            } else if let ep = enPassant, ep == to {
                // En passant: target square is empty; captured pawn sits beside us.
                moves.append(Move(from: from, to: to))
            }
        }
    }

    /// Emit a pawn move, expanding into the four promotion choices on the last rank.
    private func appendPawnDestination(from: Square, to: Square, promoRank: Int, into moves: inout [Move]) {
        if to.rank == promoRank {
            for promo in PieceType.promotionChoices {
                moves.append(Move(from: from, to: to, promotion: promo))
            }
        } else {
            moves.append(Move(from: from, to: to))
        }
    }

    /// Castling: king & rook unmoved (rights present), squares between empty, and the
    /// king does not start in, pass through, or land on an attacked square.
    private func appendCastlingMoves(color: PieceColor, into moves: inout [Move]) {
        let rank = color == .white ? 0 : 7
        guard let kingSq = Square(file: 4, rank: rank),
              let king = piece(at: kingSq), king.type == .king, king.color == color else { return }
        // Cannot castle out of check.
        let enemy = color.opposite
        if isSquareAttacked(kingSq, by: enemy) { return }

        let kingSide = color == .white ? castling.whiteKingSide : castling.blackKingSide
        let queenSide = color == .white ? castling.whiteQueenSide : castling.blackQueenSide

        // King-side: squares f & g empty; f, g not attacked; rook on h.
        if kingSide,
           let f = Square(file: 5, rank: rank),
           let g = Square(file: 6, rank: rank),
           let rookSq = Square(file: 7, rank: rank),
           piece(at: f) == nil, piece(at: g) == nil,
           let rook = piece(at: rookSq), rook.type == .rook, rook.color == color,
           !isSquareAttacked(f, by: enemy), !isSquareAttacked(g, by: enemy) {
            moves.append(Move(from: kingSq, to: g))
        }

        // Queen-side: squares b, c, d empty; d, c not attacked; rook on a.
        if queenSide,
           let b = Square(file: 1, rank: rank),
           let c = Square(file: 2, rank: rank),
           let d = Square(file: 3, rank: rank),
           let rookSq = Square(file: 0, rank: rank),
           piece(at: b) == nil, piece(at: c) == nil, piece(at: d) == nil,
           let rook = piece(at: rookSq), rook.type == .rook, rook.color == color,
           !isSquareAttacked(d, by: enemy), !isSquareAttacked(c, by: enemy) {
            moves.append(Move(from: kingSq, to: c))
        }
    }
}
