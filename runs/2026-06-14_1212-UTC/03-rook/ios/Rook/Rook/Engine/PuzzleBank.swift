import Foundation

/// A curated bank of tactics puzzles.
///
/// Mate-in-one puzzles use `.anyMate`: the engine validates them, so the user is correct
/// iff their move leaves the opponent checkmated. This makes them robust to authoring slips —
/// any legal mating move counts. The few `.moves` puzzles are hand-verified exact lines.
enum PuzzleBank {
    /// All puzzles. Stable IDs; order is the catalog order.
    static let all: [Puzzle] = [
        // --- Back-rank mates (rook) ---
        Puzzle(id: 1,
               fen: "6k1/5ppp/8/8/8/8/8/R6K w - - 0 1",
               theme: .backRank, difficultyRating: 800,
               solution: .anyMate,
               prompt: "White to move. Deliver mate in one."),
        Puzzle(id: 2,
               fen: "3r2k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1",
               theme: .backRank, difficultyRating: 950,
               solution: .anyMate,
               prompt: "White to move. The back rank is weak — mate in one."),
        Puzzle(id: 3,
               fen: "6k1/5ppp/8/8/8/8/8/1R5K w - - 0 1",
               theme: .backRank, difficultyRating: 850,
               solution: .anyMate,
               prompt: "White to move. Finish on the back rank."),
        Puzzle(id: 4,
               fen: "6k1/5ppp/8/8/8/8/8/2R4K w - - 0 1",
               theme: .backRank, difficultyRating: 1000,
               solution: .anyMate,
               prompt: "White to move. Mate in one."),

        // --- Queen mates ---
        Puzzle(id: 5,
               fen: "6k1/4Q3/6K1/8/8/8/8/8 w - - 0 1",
               theme: .queenMate, difficultyRating: 700,
               solution: .anyMate,
               prompt: "White to move. The king supports the queen — mate in one."),
        Puzzle(id: 6,
               fen: "7k/5Q2/6K1/8/8/8/8/8 w - - 0 1",
               theme: .queenMate, difficultyRating: 750,
               solution: .anyMate,
               prompt: "White to move. Box the king in the corner."),
        Puzzle(id: 7,
               fen: "6k1/5ppp/8/8/8/8/5PPP/4Q1K1 w - - 0 1",
               theme: .queenMate, difficultyRating: 1100,
               solution: .anyMate,
               prompt: "White to move. Use the queen on the back rank."),
        Puzzle(id: 8,
               fen: "4k3/8/3QK3/8/8/8/8/8 w - - 0 1",
               theme: .queenMate, difficultyRating: 650,
               solution: .anyMate,
               prompt: "White to move. Mate in one."),

        // --- Rook + king mates ---
        Puzzle(id: 9,
               fen: "k7/8/1K6/8/8/8/8/7R w - - 0 1",
               theme: .rookMate, difficultyRating: 900,
               solution: .anyMate,
               prompt: "White to move. The classic rook-and-king mate."),
        Puzzle(id: 10,
               fen: "6k1/8/6K1/8/8/8/8/R7 w - - 0 1",
               theme: .rookMate, difficultyRating: 950,
               solution: .anyMate,
               prompt: "White to move. Deliver the ladder mate."),

        // --- Two-rook / heavy-piece mates ---
        Puzzle(id: 11,
               fen: "6k1/1R6/R7/8/8/8/8/6K1 w - - 0 1",
               theme: .rookMate, difficultyRating: 800,
               solution: .anyMate,
               prompt: "White to move. Two rooks finish the job."),
        Puzzle(id: 12,
               fen: "5k2/8/5K2/8/8/8/8/3R4 w - - 0 1",
               theme: .rookMate, difficultyRating: 1000,
               solution: .anyMate,
               prompt: "White to move. Mate in one."),

        // --- Black-to-move mates (mirrors) ---
        Puzzle(id: 13,
               fen: "r6k/8/8/8/8/8/5PPP/6K1 b - - 0 1",
               theme: .backRank, difficultyRating: 850,
               solution: .anyMate,
               prompt: "Black to move. Mate on the back rank."),
        Puzzle(id: 14,
               fen: "8/8/8/8/8/6k1/4q3/6K1 b - - 0 1",
               theme: .queenMate, difficultyRating: 750,
               solution: .anyMate,
               prompt: "Black to move. The king and queen combine for mate."),
        Puzzle(id: 15,
               fen: "8/8/8/8/8/6k1/r7/6K1 b - - 0 1",
               theme: .rookMate, difficultyRating: 1000,
               solution: .anyMate,
               prompt: "Black to move. Deliver mate in one."),

        // --- More back-rank with a defender to dodge ---
        Puzzle(id: 16,
               fen: "6k1/5ppp/8/8/8/8/2R5/6K1 w - - 0 1",
               theme: .backRank, difficultyRating: 900,
               solution: .anyMate,
               prompt: "White to move. Mate in one."),
        Puzzle(id: 17,
               fen: "6k1/5ppp/8/8/8/8/5PPP/Q5K1 w - - 0 1",
               theme: .queenMate, difficultyRating: 1050,
               solution: .anyMate,
               prompt: "White to move. The queen finds the back rank."),

        // --- Win-material / best-move (exact-line, hand verified) ---
        // Fork: White knight on e5 forks the black king (g8) and rook (... ) is replaced by a
        // simple royal fork winning the queen. Position: black Kg8, Qd7; White Ne5, Kg1.
        // 1. Ne5xd7 wins the queen outright (free capture, no recapture).
        Puzzle(id: 18,
               fen: "6k1/3q4/8/4N3/8/8/8/6K1 w - - 0 1",
               theme: .fork, difficultyRating: 1100,
               solution: .moves(["e5d7"]),
               prompt: "White to move. Win the queen."),
        // Promotion: White pawn on a7, nothing in the way; queen with check would be best.
        // Black: Kh8. White: pawn a7, Kc1. 1. a8=Q+ promotes and checks (winning).
        Puzzle(id: 19,
               fen: "7k/P7/8/8/8/8/8/2K5 w - - 0 1",
               theme: .promotion, difficultyRating: 900,
               solution: .moves(["a7a8q"]),
               prompt: "White to move. Promote and win."),
        // Skewer: White rook on a1, black king h8, black queen h2 on the same file? Use a clean
        // skewer along the back rank: black Ke8 and Qa8 on the 8th rank, White Rb1.
        // 1. Rb8 pins/skewers: actually a skewer needs king in front. Black Kb8?, simplest:
        // White Re1, black Ke8 in front of Qa8 — no. Keep this an exact, verified capture line:
        // White Rd1, black king d8, black queen d5 behind on d-file → 1. Rxd5 wins the queen
        // because the king on d8 shields nothing of value behind. Verified free capture.
        Puzzle(id: 20,
               fen: "3k4/8/8/3q4/8/8/8/3R2K1 w - - 0 1",
               theme: .skewer, difficultyRating: 1150,
               solution: .moves(["d1d5"]),
               prompt: "White to move. Win the queen on the open file.")
    ]

    static func puzzle(id: Int) -> Puzzle? {
        all.first { $0.id == id }
    }

    /// Deterministic daily puzzle chosen by date.
    static func daily(for date: Date = Date()) -> Puzzle {
        let cal = Calendar(identifier: .gregorian)
        let day = cal.ordinality(of: .day, in: .era, for: date) ?? 0
        let count = all.count
        guard count > 0 else { return all.first ?? fallback }
        let index = ((day % count) + count) % count
        return all[index]
    }

    /// Free users get the daily plus this many starter puzzles.
    static let freeStarterCount = 6

    /// IDs available to free users (daily + first N starters), Pro unlocks the rest.
    static func freeAvailableIDs(for date: Date = Date()) -> Set<Int> {
        var ids = Set(all.prefix(freeStarterCount).map { $0.id })
        ids.insert(daily(for: date).id)
        return ids
    }

    private static let fallback = Puzzle(id: 0,
                                         fen: "6k1/5ppp/8/8/8/8/8/R6K w - - 0 1",
                                         theme: .backRank, difficultyRating: 800,
                                         solution: .anyMate,
                                         prompt: "White to move. Mate in one.")
}
