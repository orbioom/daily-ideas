import Foundation

// MARK: - Difficulty

enum Difficulty: String, CaseIterable, Codable {
    case easy   = "easy"
    case medium = "medium"
    case hard   = "hard"

    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }

    var depth: Int {
        switch self {
        case .easy:   return 2
        case .medium: return 4
        case .hard:   return 6
        }
    }
}

// MARK: - AI

struct CheckersAI: Sendable {

    // MARK: Public API

    /// Returns the best move for the AI player on the given board.
    func bestMove(for board: CheckersBoard, difficulty: Difficulty) -> CheckersMove? {
        let moves = board.validMoves(for: board.currentPlayer)
        guard !moves.isEmpty else { return nil }

        // Easy difficulty: occasionally pick a random move (30% of the time) to feel human.
        if difficulty == .easy, Int.random(in: 0..<10) < 3 {
            return moves.randomElement()
        }

        let isMaximising = board.currentPlayer == .red
        var bestValue: Double = isMaximising ? -Double.infinity : Double.infinity
        var bestMove: CheckersMove = moves[0]

        // Order moves: jumps first for better alpha-beta pruning.
        let orderedMoves = orderMoves(moves)

        for move in orderedMoves {
            let nextBoard = board.applyMove(move)
            let value = minimax(
                board: nextBoard,
                depth: difficulty.depth - 1,
                alpha: -Double.infinity,
                beta: Double.infinity,
                isMaximising: !isMaximising
            )

            if isMaximising {
                if value > bestValue {
                    bestValue = value
                    bestMove = move
                }
            } else {
                if value < bestValue {
                    bestValue = value
                    bestMove = move
                }
            }
        }

        return bestMove
    }

    // MARK: Minimax

    private func minimax(
        board: CheckersBoard,
        depth: Int,
        alpha: Double,
        beta: Double,
        isMaximising: Bool
    ) -> Double {
        if depth == 0 || board.isTerminal {
            return evaluate(board)
        }

        let moves = orderMoves(board.validMoves(for: board.currentPlayer))
        var alpha = alpha
        var beta = beta

        if isMaximising {
            var maxEval = -Double.infinity
            for move in moves {
                let child = board.applyMove(move)
                let eval = minimax(board: child, depth: depth - 1, alpha: alpha, beta: beta, isMaximising: false)
                maxEval = max(maxEval, eval)
                alpha = max(alpha, eval)
                if beta <= alpha { break }
            }
            return maxEval
        } else {
            var minEval = Double.infinity
            for move in moves {
                let child = board.applyMove(move)
                let eval = minimax(board: child, depth: depth - 1, alpha: alpha, beta: beta, isMaximising: true)
                minEval = min(minEval, eval)
                beta = min(beta, eval)
                if beta <= alpha { break }
            }
            return minEval
        }
    }

    // MARK: Evaluation

    /// Positive = good for red, negative = good for black.
    private func evaluate(_ board: CheckersBoard) -> Double {
        if board.isTerminal {
            guard let winner = board.winner() else { return 0 }
            return winner == .red ? 1000 : -1000
        }

        var score: Double = 0

        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = board.cells[row][col] else { continue }
                let sign: Double = piece.player == .red ? 1 : -1

                // Base piece value
                let pieceValue: Double = piece.type == .king ? 2.5 : 1.0

                // King bonus
                let kingBonus: Double = piece.type == .king ? 1.5 : 0

                // Position bonus: encourage advancement for men
                var positionBonus: Double = 0
                if piece.type == .man {
                    if piece.player == .red {
                        // Red advances toward row 7
                        positionBonus = Double(row) * 0.05
                    } else {
                        // Black advances toward row 0
                        positionBonus = Double(7 - row) * 0.05
                    }
                }

                // Centre control bonus
                let centreBonus: Double
                if (row >= 3 && row <= 4) && (col >= 3 && col <= 4) {
                    centreBonus = 0.15
                } else if (row >= 2 && row <= 5) && (col >= 2 && col <= 5) {
                    centreBonus = 0.05
                } else {
                    centreBonus = 0
                }

                // Edge penalty for kings (less mobility on edge)
                let edgePenalty: Double = piece.type == .king && (col == 0 || col == 7) ? -0.1 : 0

                score += sign * (pieceValue + kingBonus + positionBonus + centreBonus + edgePenalty)
            }
        }

        return score
    }

    // MARK: Move Ordering

    private func orderMoves(_ moves: [CheckersMove]) -> [CheckersMove] {
        // Jumps before non-jumps; multi-jumps (more captures) first
        return moves.sorted { a, b in
            if a.isJump != b.isJump { return a.isJump }
            return a.captures.count > b.captures.count
        }
    }
}
