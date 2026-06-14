import Foundation

extension Board {
    /// Evaluate the game status from the side-to-move's perspective.
    /// Pass the position history (FENs without clock fields) to detect threefold.
    func status(repetitionFENs: [String] = []) -> GameStatus {
        let side = sideToMove
        let inCheck = kingInCheck(color: side)
        let hasMoves = !legalMoves().isEmpty

        if !hasMoves {
            if inCheck {
                return .checkmate(winner: side.opposite)
            } else {
                return .stalemate
            }
        }

        if isInsufficientMaterial() {
            return .insufficientMaterial
        }
        if halfmoveClock >= 100 {
            return .fiftyMoveRule
        }
        // Threefold: the current position key occurring three+ times.
        if !repetitionFENs.isEmpty {
            let key = repetitionKey
            let count = repetitionFENs.filter { $0 == key }.count
            if count >= 3 { return .threefold }
        }

        return inCheck ? .check(side) : .ongoing
    }

    /// A position key for repetition detection: placement + side + castling + en passant.
    var repetitionKey: String {
        let parts = fen.split(separator: " ").map(String.init)
        // Use the first four FEN fields (placement, side, castling, en passant).
        guard parts.count >= 4 else { return fen }
        return parts[0...3].joined(separator: " ")
    }

    /// Standard insufficient-material draws: K vs K, K+minor vs K, K+B vs K+B (same color bishops).
    func isInsufficientMaterial() -> Bool {
        var whiteMinors: [PieceType] = []
        var blackMinors: [PieceType] = []
        var bishopSquareColors: [Int] = []   // 0 = light, 1 = dark, per bishop

        for idx in 0..<64 {
            guard let p = squares[idx] else { continue }
            switch p.type {
            case .king:
                continue
            case .pawn, .rook, .queen:
                // Any pawn, rook, or queen means material is sufficient.
                return false
            case .knight, .bishop:
                if p.color == .white { whiteMinors.append(p.type) } else { blackMinors.append(p.type) }
                if p.type == .bishop, let sq = Square(index: idx) {
                    bishopSquareColors.append((sq.file + sq.rank) % 2)
                }
            }
        }

        let total = whiteMinors.count + blackMinors.count
        // K vs K.
        if total == 0 { return true }
        // K + single minor vs K.
        if total == 1 { return true }
        // K+B vs K+B with bishops on same-colored squares.
        if whiteMinors == [.bishop], blackMinors == [.bishop],
           bishopSquareColors.count == 2, bishopSquareColors[0] == bishopSquareColors[1] {
            return true
        }
        return false
    }

    /// Convenience: does the side to move have any legal move?
    var hasLegalMove: Bool { !legalMoves().isEmpty }
}
