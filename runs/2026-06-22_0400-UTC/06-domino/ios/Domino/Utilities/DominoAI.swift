import Foundation

struct DominoAI {
    static func chooseMove(
        hand: [DominoTile],
        validMoves: [(tile: DominoTile, end: DominoEngine.ChainEnd)],
        playerHandCount: Int,
        difficulty: DominoEngine.AIDifficulty
    ) -> (tile: DominoTile, end: DominoEngine.ChainEnd)? {
        guard !validMoves.isEmpty else { return nil }

        switch difficulty {
        case .easy:
            // Random move
            return validMoves.randomElement()

        case .medium:
            // Prefer playing doubles first (they can't be played on both ends unlike non-doubles)
            // Then play tiles with the highest pip count to minimize remaining points
            let sorted = validMoves.sorted { a, b in
                if a.tile.isDouble != b.tile.isDouble { return a.tile.isDouble }
                return a.tile.totalPips > b.tile.totalPips
            }
            return sorted.first

        case .hard:
            // Minimize remaining pip count in hand while preferring doubles
            // Also prefer moves that create more blocking opportunities
            let best = validMoves.min { a, b in
                let aRemainingPips = hand.filter { $0 != a.tile }.reduce(0) { $0 + $1.totalPips }
                let bRemainingPips = hand.filter { $0 != b.tile }.reduce(0) { $0 + $1.totalPips }

                // Strongly prefer removing doubles (they can block us if left)
                if a.tile.isDouble && !b.tile.isDouble { return true }
                if !a.tile.isDouble && b.tile.isDouble { return false }

                return aRemainingPips < bRemainingPips
            }
            return best
        }
    }
}
