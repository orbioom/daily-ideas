import Foundation

/// The two sides.
enum PieceColor: Int, Codable, Hashable, Sendable {
    case white
    case black

    var opposite: PieceColor { self == .white ? .black : .white }
}

/// Piece kinds.
enum PieceType: Int, Codable, Hashable, CaseIterable, Sendable {
    case pawn
    case knight
    case bishop
    case rook
    case queen
    case king

    /// Centipawn material value used by the evaluator.
    var value: Int {
        switch self {
        case .pawn: return 100
        case .knight: return 320
        case .bishop: return 330
        case .rook: return 500
        case .queen: return 900
        case .king: return 0
        }
    }

    /// Lowercase letter used in FEN / SAN.
    var letter: Character {
        switch self {
        case .pawn: return "p"
        case .knight: return "n"
        case .bishop: return "b"
        case .rook: return "r"
        case .queen: return "q"
        case .king: return "k"
        }
    }

    /// Promotion targets, excluding king and pawn.
    static let promotionChoices: [PieceType] = [.queen, .rook, .bishop, .knight]
}

/// A single piece on the board.
struct Piece: Equatable, Hashable, Codable, Sendable {
    let color: PieceColor
    let type: PieceType

    /// FEN character: uppercase for white, lowercase for black.
    var fenChar: Character {
        let base = type.letter
        return color == .white ? Character(base.uppercased()) : base
    }

    /// Unicode glyph for this piece. We always render the *filled* (black) glyphs and
    /// color them ourselves, which gives a clean, consistent tournament look.
    var glyph: String {
        switch type {
        case .king: return "\u{265A}"   // ♚
        case .queen: return "\u{265B}"  // ♛
        case .rook: return "\u{265C}"   // ♜
        case .bishop: return "\u{265D}" // ♝
        case .knight: return "\u{265E}" // ♞
        case .pawn: return "\u{265F}"   // ♟
        }
    }
}

/// A board square encoded as 0...63, with 0 = a1, 7 = h1, 56 = a8, 63 = h8.
struct Square: Equatable, Hashable, Codable, Sendable {
    /// 0...63. Guard at construction; callers should only build valid squares.
    let index: Int

    init?(index: Int) {
        guard (0..<64).contains(index) else { return nil }
        self.index = index
    }

    /// File 0...7 (a...h) and rank 0...7 (1...8).
    init?(file: Int, rank: Int) {
        guard (0..<8).contains(file), (0..<8).contains(rank) else { return nil }
        self.index = rank * 8 + file
    }

    /// Private direct initializer for known-valid indices (avoids optionals internally).
    private init(validatedIndex: Int) {
        self.index = validatedIndex
    }

    /// The a1 square (index 0). A safe, always-valid sentinel.
    static let a1 = Square(validatedIndex: 0)

    var file: Int { index % 8 }
    var rank: Int { index / 8 }

    /// Algebraic name, e.g. "e4".
    var name: String {
        let files = "abcdefgh"
        let fi = file
        guard (0..<8).contains(fi) else { return "??" }
        let fileChar = files[files.index(files.startIndex, offsetBy: fi)]
        return "\(fileChar)\(rank + 1)"
    }

    /// Parse "e4" style names.
    init?(name: String) {
        let chars = Array(name.lowercased())
        guard chars.count == 2 else { return nil }
        let files = "abcdefgh"
        guard let fileIdx = files.firstIndex(of: chars[0]) else { return nil }
        let file = files.distance(from: files.startIndex, to: fileIdx)
        guard let rankDigit = chars[1].wholeNumberValue, (1...8).contains(rankDigit) else { return nil }
        self.init(file: file, rank: rankDigit - 1)
    }
}

/// A move from one square to another, with optional promotion piece.
struct Move: Equatable, Hashable, Codable, Identifiable, Sendable {
    let from: Square
    let to: Square
    let promotion: PieceType?

    var id: String { uci }

    init(from: Square, to: Square, promotion: PieceType? = nil) {
        self.from = from
        self.to = to
        self.promotion = promotion
    }

    /// UCI long algebraic, e.g. "e2e4" or "e7e8q".
    var uci: String {
        var s = from.name + to.name
        if let promotion {
            s.append(promotion.letter)
        }
        return s
    }

    /// Parse a UCI string into a move (geometry only; legality checked separately).
    init?(uci: String) {
        let chars = Array(uci.lowercased())
        guard chars.count == 4 || chars.count == 5 else { return nil }
        guard let from = Square(name: String(chars[0...1])),
              let to = Square(name: String(chars[2...3])) else { return nil }
        var promo: PieceType? = nil
        if chars.count == 5 {
            switch chars[4] {
            case "q": promo = .queen
            case "r": promo = .rook
            case "b": promo = .bishop
            case "n": promo = .knight
            default: return nil
            }
        }
        self.init(from: from, to: to, promotion: promo)
    }
}

/// Castling rights bitmask helpers.
struct CastlingRights: Equatable, Hashable, Codable, Sendable {
    var whiteKingSide: Bool
    var whiteQueenSide: Bool
    var blackKingSide: Bool
    var blackQueenSide: Bool

    static let none = CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                     blackKingSide: false, blackQueenSide: false)

    /// FEN field e.g. "KQkq" or "-".
    var fenField: String {
        var s = ""
        if whiteKingSide { s += "K" }
        if whiteQueenSide { s += "Q" }
        if blackKingSide { s += "k" }
        if blackQueenSide { s += "q" }
        return s.isEmpty ? "-" : s
    }
}

/// Terminal/ongoing status of a game.
enum GameStatus: Equatable {
    case ongoing
    case check(PieceColor)            // side to move is in check
    case checkmate(winner: PieceColor)
    case stalemate
    case insufficientMaterial
    case fiftyMoveRule
    case threefold

    var isTerminal: Bool {
        switch self {
        case .ongoing, .check: return false
        default: return true
        }
    }
}
