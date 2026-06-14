import Foundation

/// Difficulty levels mapping to search depth.
enum AILevel: Int, CaseIterable, Identifiable, Codable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3

    var id: Int { rawValue }
    var depth: Int { rawValue }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var blurb: String {
        switch self {
        case .easy: return "Looks one move ahead — gentle and forgiving."
        case .medium: return "Searches two plies — a solid club opponent."
        case .hard: return "Searches three plies — plans short tactics."
        }
    }
}

/// Negamax with alpha-beta pruning over the value-semantics `Board`.
/// Self-contained and side-effect free; safe to run on a background task.
struct ChessAI: Sendable {
    let level: AILevel

    private let mateScore = 1_000_000
    private let infinity = 10_000_000

    /// Choose the best move for the side to move, or nil if there are none.
    func bestMove(for board: Board) -> Move? {
        let moves = orderedMoves(board)
        guard !moves.isEmpty else { return nil }

        var bestMove = moves[0]
        var bestScore = -infinity
        var alpha = -infinity
        let beta = infinity
        let depth = max(1, level.depth)

        for move in moves {
            let child = board.applyingUnchecked(move)
            // Negamax: score from the child's perspective, negated.
            let score = -negamax(child, depth: depth - 1, alpha: -beta, beta: -alpha)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
            if score > alpha { alpha = score }
        }
        return bestMove
    }

    /// Negamax score relative to `board.sideToMove` (positive = good for them).
    private func negamax(_ board: Board, depth: Int, alpha: Int, beta: Int) -> Int {
        let moves = orderedMoves(board)

        // Terminal: no legal moves.
        if moves.isEmpty {
            if board.kingInCheck(color: board.sideToMove) {
                // Being mated is very bad; prefer later mates by adding depth.
                return -mateScore - depth
            }
            return 0 // stalemate
        }

        if depth <= 0 {
            return sideRelativeEval(board)
        }

        var alpha = alpha
        var best = -infinity
        for move in moves {
            let child = board.applyingUnchecked(move)
            let score = -negamax(child, depth: depth - 1, alpha: -beta, beta: -alpha)
            if score > best { best = score }
            if best > alpha { alpha = best }
            if alpha >= beta { break } // beta cutoff
        }
        return best
    }

    /// White-perspective eval flipped to the side to move.
    private func sideRelativeEval(_ board: Board) -> Int {
        let white = Evaluation.evaluate(board)
        return board.sideToMove == .white ? white : -white
    }

    /// Legal moves, captures first (cheap move ordering to help alpha-beta).
    private func orderedMoves(_ board: Board) -> [Move] {
        let moves = board.legalMoves()
        return moves.sorted { a, b in
            captureValue(board, a) > captureValue(board, b)
        }
    }

    /// MVV-LVA-ish capture priority for ordering.
    private func captureValue(_ board: Board, _ move: Move) -> Int {
        var v = 0
        if let victim = board.piece(at: move.to) {
            v += victim.type.value * 10
        }
        if let attacker = board.piece(at: move.from) {
            v -= attacker.type.value
        }
        if move.promotion != nil { v += 800 }
        return v
    }
}
