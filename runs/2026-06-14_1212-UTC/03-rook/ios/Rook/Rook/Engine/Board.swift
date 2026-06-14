import Foundation

/// Immutable-by-convention chess board with full rule support. Value semantics:
/// `makeMove` returns a NEW board, so undo is just keeping the old value.
struct Board: Equatable, Sendable {
    /// 64 squares, index 0 = a1 ... 63 = h8. `nil` means empty.
    private(set) var squares: [Piece?]
    private(set) var sideToMove: PieceColor
    private(set) var castling: CastlingRights
    /// En passant *target* square (the square a capturing pawn would move TO), or nil.
    private(set) var enPassant: Square?
    private(set) var halfmoveClock: Int
    private(set) var fullmoveNumber: Int

    init(squares: [Piece?],
         sideToMove: PieceColor,
         castling: CastlingRights,
         enPassant: Square?,
         halfmoveClock: Int,
         fullmoveNumber: Int) {
        // Defensive: always keep exactly 64 cells.
        if squares.count == 64 {
            self.squares = squares
        } else {
            var fixed = Array<Piece?>(repeating: nil, count: 64)
            for i in 0..<min(64, squares.count) { fixed[i] = squares[i] }
            self.squares = fixed
        }
        self.sideToMove = sideToMove
        self.castling = castling
        self.enPassant = enPassant
        self.halfmoveClock = halfmoveClock
        self.fullmoveNumber = fullmoveNumber
    }

    // MARK: - Access

    func piece(at sq: Square) -> Piece? {
        guard (0..<64).contains(sq.index) else { return nil }
        return squares[sq.index]
    }

    func piece(file: Int, rank: Int) -> Piece? {
        guard let sq = Square(file: file, rank: rank) else { return nil }
        return squares[sq.index]
    }

    /// Locate the king of a given color. Returns nil only for malformed positions.
    func kingSquare(of color: PieceColor) -> Square? {
        for i in 0..<64 {
            if let p = squares[i], p.type == .king, p.color == color {
                return Square(index: i)
            }
        }
        return nil
    }

    // MARK: - Standard start position

    static var standard: Board {
        // Failsafe FEN parse — the literal is known-good.
        if let b = Board(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") {
            return b
        }
        // Should never happen; provide an empty board rather than crashing.
        return Board(squares: Array(repeating: nil, count: 64),
                     sideToMove: .white,
                     castling: .none,
                     enPassant: nil,
                     halfmoveClock: 0,
                     fullmoveNumber: 1)
    }
}
