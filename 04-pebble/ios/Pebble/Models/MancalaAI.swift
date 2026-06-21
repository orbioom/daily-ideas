import Foundation

enum MancalaAI {
    /// Returns the best pit index for the current player on the given board.
    /// difficulty: 0 = Easy (depth 2, occasional random), 1 = Medium (depth 4), 2 = Hard (depth 6)
    static func bestMove(board: MancalaBoard, difficulty: Int) -> Int {
        let depth = [2, 4, 6][min(difficulty, 2)]
        let moves = board.validMoves(for: board.currentPlayer)
        guard !moves.isEmpty else { return -1 }

        // On Easy, occasionally pick a random move to feel more human.
        if difficulty == 0 && Int.random(in: 0..<3) == 0 {
            return moves.randomElement()!
        }

        var bestScore = Int.min
        var bestMove = moves[0]
        for move in moves {
            var b = board
            let extra = b.sow(pit: move)
            let score: Int
            if extra && !b.isGameOver {
                // AI gets an extra turn — continue maximising.
                score = minimax(board: b, depth: depth - 1, alpha: Int.min, beta: Int.max,
                                maximizing: true, aiPlayer: board.currentPlayer)
            } else {
                score = minimax(board: b, depth: depth - 1, alpha: Int.min, beta: Int.max,
                                maximizing: false, aiPlayer: board.currentPlayer)
            }
            if score > bestScore { bestScore = score; bestMove = move }
        }
        return bestMove
    }

    private static func minimax(board: MancalaBoard, depth: Int, alpha: Int, beta: Int,
                                 maximizing: Bool, aiPlayer: Int) -> Int {
        if board.isGameOver || depth == 0 {
            return evaluate(board: board, aiPlayer: aiPlayer)
        }
        var a = alpha, b = beta
        let moves = board.validMoves(for: board.currentPlayer)
        if moves.isEmpty { return evaluate(board: board, aiPlayer: aiPlayer) }

        if maximizing {
            var best = Int.min
            for move in moves {
                var nb = board
                let extra = nb.sow(pit: move)
                let childMax = extra && !nb.isGameOver
                let score = minimax(board: nb, depth: depth - 1, alpha: a, beta: b,
                                    maximizing: childMax, aiPlayer: aiPlayer)
                best = max(best, score)
                a = max(a, best)
                if b <= a { break }
            }
            return best
        } else {
            var best = Int.max
            for move in moves {
                var nb = board
                let extra = nb.sow(pit: move)
                let childMax = extra && !nb.isGameOver
                let score = minimax(board: nb, depth: depth - 1, alpha: a, beta: b,
                                    maximizing: childMax, aiPlayer: aiPlayer)
                best = min(best, score)
                b = min(b, best)
                if b <= a { break }
            }
            return best
        }
    }

    private static func evaluate(board: MancalaBoard, aiPlayer: Int) -> Int {
        let myStore  = aiPlayer == 0 ? board.pits[6]  : board.pits[13]
        let oppStore = aiPlayer == 0 ? board.pits[13] : board.pits[6]
        return myStore - oppStore
    }
}
