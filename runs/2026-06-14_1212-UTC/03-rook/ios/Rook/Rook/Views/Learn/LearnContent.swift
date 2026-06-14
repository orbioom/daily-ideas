import Foundation

/// Static reference content for the Learn screen.
enum LearnContent {

    struct PieceLesson: Identifiable {
        let id: PieceType
        let name: String
        let glyphColor: PieceColor
        let summary: String
        /// FEN showing the piece centrally with its move squares implied by description.
        let fen: String
        /// Squares to highlight as reachable destinations (for the diagram).
        let highlights: [String]
    }

    struct TacticLesson: Identifiable {
        let id: String
        let name: String
        let summary: String
        let fen: String
        let highlights: [String]
        let flipped: Bool
    }

    // MARK: Piece movement (a lone piece on d4/e4, highlights mark legal destinations)

    static let pieces: [PieceLesson] = [
        PieceLesson(id: .pawn, name: "Pawn",
                    glyphColor: .white,
                    summary: "Pawns march straight forward one square — or two from their starting rank — and capture one square diagonally. Reach the far side and a pawn promotes to any piece.",
                    fen: "8/8/8/8/3P4/8/8/8 w - - 0 1",
                    highlights: ["d5", "c5", "e5"]),
        PieceLesson(id: .knight, name: "Knight",
                    glyphColor: .white,
                    summary: "The knight jumps in an L-shape: two squares one way, then one square at a right angle. It is the only piece that leaps over others.",
                    fen: "8/8/8/8/3N4/8/8/8 w - - 0 1",
                    highlights: ["b5", "c6", "e6", "f5", "f3", "e2", "c2", "b3"]),
        PieceLesson(id: .bishop, name: "Bishop",
                    glyphColor: .white,
                    summary: "Bishops slide any distance along diagonals, staying forever on one color of square. A pair of bishops covering both colors is a real asset.",
                    fen: "8/8/8/8/3B4/8/8/8 w - - 0 1",
                    highlights: ["a1", "b2", "c3", "e5", "f6", "g7", "h8", "a7", "b6", "c5", "e3", "f2", "g1"]),
        PieceLesson(id: .rook, name: "Rook",
                    glyphColor: .white,
                    summary: "Rooks slide any distance along ranks and files. They are strongest on open files and the 7th rank, and they team up to deliver back-rank mates.",
                    fen: "8/8/8/8/3R4/8/8/8 w - - 0 1",
                    highlights: ["d1", "d2", "d3", "d5", "d6", "d7", "d8", "a4", "b4", "c4", "e4", "f4", "g4", "h4"]),
        PieceLesson(id: .queen, name: "Queen",
                    glyphColor: .white,
                    summary: "The queen combines rook and bishop: any distance along ranks, files, and diagonals. It is the most powerful piece — keep it safe in the opening.",
                    fen: "8/8/8/8/3Q4/8/8/8 w - - 0 1",
                    highlights: ["d1", "d7", "a4", "h4", "a1", "g7", "a7", "g1"]),
        PieceLesson(id: .king, name: "King",
                    glyphColor: .white,
                    summary: "The king steps one square in any direction. It can never move into check, and once per game it may castle with a rook for safety.",
                    fen: "8/8/8/8/3K4/8/8/8 w - - 0 1",
                    highlights: ["c5", "d5", "e5", "c4", "e4", "c3", "d3", "e3"])
    ]

    // MARK: Tactics glossary (real positions illustrating the motif)

    static let tactics: [TacticLesson] = [
        TacticLesson(id: "fork", name: "Fork",
                     summary: "One piece attacks two or more enemy units at once. Knights are famous forkers — here the knight hits the king and queen together, winning material.",
                     fen: "3qk3/8/4N3/8/8/8/8/4K3 w - - 0 1",
                     highlights: ["e6", "d8", "e8"],
                     flipped: false),
        TacticLesson(id: "pin", name: "Pin",
                     summary: "A piece cannot move because doing so would expose a more valuable piece behind it. Here the bishop pins the knight against the king.",
                     fen: "4k3/8/4n3/8/8/8/8/B3K3 w - - 0 1",
                     highlights: ["a1", "e6", "e8"],
                     flipped: false),
        TacticLesson(id: "skewer", name: "Skewer",
                     summary: "Like a pin in reverse: a valuable piece is attacked and forced to move, exposing a piece behind it to capture.",
                     fen: "8/8/8/8/4k3/8/4q3/4R1K1 w - - 0 1",
                     highlights: ["e1", "e2", "e4"],
                     flipped: false),
        TacticLesson(id: "discovered", name: "Discovered attack",
                     summary: "Moving one piece uncovers an attack from a piece behind it. The moving piece can make its own threat at the same time — a double whammy.",
                     fen: "4k3/8/8/4N3/8/8/8/4R1K1 w - - 0 1",
                     highlights: ["e5", "e1", "e8"],
                     flipped: false),
        TacticLesson(id: "backrank", name: "Back-rank mate",
                     summary: "A king trapped on its back rank by its own pawns can be mated by a rook or queen arriving on that rank. Make luft (an escape square) to avoid it.",
                     fen: "6k1/5ppp/8/8/8/8/8/R6K w - - 0 1",
                     highlights: ["a1", "a8", "g8"],
                     flipped: false)
    ]
}
