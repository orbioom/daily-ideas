import Foundation

extension Board {
    /// Parse a FEN string. Returns nil on any malformed input (all indices guarded).
    init?(fen: String) {
        let trimmed = fen.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard parts.count >= 4 else { return nil }

        let placement = parts[0]
        let activeColor = parts[1]
        let castlingField = parts[2]
        let epField = parts[3]
        let halfmoveField = parts.count >= 5 ? parts[4] : "0"
        let fullmoveField = parts.count >= 6 ? parts[5] : "1"

        // --- Piece placement ---
        var board = Array<Piece?>(repeating: nil, count: 64)
        let ranks = placement.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard ranks.count == 8 else { return nil }

        // FEN ranks go from 8 (top) down to 1 (bottom). Our index 56..63 is rank 8.
        for (rowIndex, rankStr) in ranks.enumerated() {
            let rank = 7 - rowIndex   // rowIndex 0 -> rank 7 (the 8th rank)
            var file = 0
            for ch in rankStr {
                if let digit = ch.wholeNumberValue, (1...8).contains(digit) {
                    file += digit
                    if file > 8 { return nil }
                } else {
                    guard file < 8 else { return nil }
                    guard let piece = Board.piece(fromFenChar: ch) else { return nil }
                    let idx = rank * 8 + file
                    guard (0..<64).contains(idx) else { return nil }
                    board[idx] = piece
                    file += 1
                }
            }
            guard file == 8 else { return nil }
        }

        // --- Active color ---
        let side: PieceColor
        switch activeColor {
        case "w": side = .white
        case "b": side = .black
        default: return nil
        }

        // --- Castling ---
        var rights = CastlingRights.none
        if castlingField != "-" {
            for ch in castlingField {
                switch ch {
                case "K": rights.whiteKingSide = true
                case "Q": rights.whiteQueenSide = true
                case "k": rights.blackKingSide = true
                case "q": rights.blackQueenSide = true
                default: return nil
                }
            }
        }

        // --- En passant ---
        var ep: Square? = nil
        if epField != "-" {
            guard let sq = Square(name: epField) else { return nil }
            ep = sq
        }

        // --- Clocks ---
        let half = max(0, Int(halfmoveField) ?? 0)
        let full = max(1, Int(fullmoveField) ?? 1)

        self.init(squares: board,
                  sideToMove: side,
                  castling: rights,
                  enPassant: ep,
                  halfmoveClock: half,
                  fullmoveNumber: full)
    }

    private static func piece(fromFenChar ch: Character) -> Piece? {
        let color: PieceColor = ch.isUppercase ? .white : .black
        let type: PieceType
        switch Character(ch.lowercased()) {
        case "p": type = .pawn
        case "n": type = .knight
        case "b": type = .bishop
        case "r": type = .rook
        case "q": type = .queen
        case "k": type = .king
        default: return nil
        }
        return Piece(color: color, type: type)
    }

    /// Generate a FEN string for the current position.
    var fen: String {
        var rows: [String] = []
        for rowIndex in 0..<8 {
            let rank = 7 - rowIndex
            var row = ""
            var empty = 0
            for file in 0..<8 {
                let idx = rank * 8 + file
                if (0..<64).contains(idx), let p = squares[idx] {
                    if empty > 0 { row += String(empty); empty = 0 }
                    row.append(p.fenChar)
                } else {
                    empty += 1
                }
            }
            if empty > 0 { row += String(empty) }
            rows.append(row)
        }
        let placement = rows.joined(separator: "/")
        let side = sideToMove == .white ? "w" : "b"
        let ep = enPassant?.name ?? "-"
        return "\(placement) \(side) \(castling.fenField) \(ep) \(halfmoveClock) \(fullmoveNumber)"
    }
}
