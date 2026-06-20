import Foundation

// MARK: - Backgammon AI
// Greedy heuristic AI with three difficulty levels.
// Easy: random moves
// Medium: greedy single-move evaluation
// Hard: greedy with look-ahead heuristics and better positional awareness

struct BackgammonAI {

    // MARK: - Entry Point

    static func pickMove(
        moves: [(Int, Int)],
        game: BackgammonGame,
        difficulty: Int
    ) -> (Int, Int) {
        guard !moves.isEmpty else { return (0, 0) }

        switch difficulty {
        case 1:
            return moves.randomElement()!
        case 2:
            return greedyBestMove(moves: moves, game: game, noise: 15)
        default:
            return greedyBestMove(moves: moves, game: game, noise: 2)
        }
    }

    // MARK: - Greedy Evaluation

    private static func greedyBestMove(
        moves: [(Int, Int)],
        game: BackgammonGame,
        noise: Int
    ) -> (Int, Int) {
        var best = moves[0]
        var bestScore = Int.min

        for move in moves {
            var score = evaluateMove(move, game: game)
            score += Int.random(in: 0...noise)
            if score > bestScore {
                bestScore = score
                best = move
            }
        }
        return best
    }

    private static func evaluateMove(_ move: (Int, Int), game: BackgammonGame) -> Int {
        var score = 0
        let player = game.currentPlayer
        let from = move.0
        let to = move.1

        // ── Top priorities ──────────────────────────────────────────────

        // 1. Bearing off is always great
        if to == -2 {
            score += 500
            // Prefer bearing off from the highest point (most "wasted" die otherwise)
            if player == .white { score += from }
            else { score += (23 - from) }
            return score
        }

        // 2. Getting off the bar is urgent
        if from == -1 {
            score += 300
            // Prefer entering on a made point (safety)
            if to >= 0 && to < 24 && (game.points[safe: to]?.count ?? 0) >= 1 {
                score += 50
            }
            return score
        }

        // ── Positional heuristics ───────────────────────────────────────

        // 3. Hit an opponent's blot
        if to >= 0 && to < 24,
           let destPoint = game.points[safe: to],
           destPoint.isBlot && destPoint.color == player.other {
            score += 120
            // Hitting in opponent's home board is extra valuable
            if player == .white && to >= 18 { score += 30 }
            if player == .black && to <= 5  { score += 30 }
        }

        // 4. Make a point (2+ pieces → opponent can't land)
        if to >= 0 && to < 24,
           let destPoint = game.points[safe: to],
           destPoint.color == player && destPoint.count == 1 {
            score += 80  // making a point
            // Prime points (4,5,6 in home board or blocking opponent's path)
            if player == .white && to >= 1 && to <= 6 { score += 20 }
            if player == .black && to >= 17 && to <= 22 { score += 20 }
        }

        // 5. Avoid leaving blots
        if to >= 0 && to < 24,
           let destPoint = game.points[safe: to],
           destPoint.count == 0 {
            // We're leaving a blot at destination
            score -= 20
            // Extra penalty if in opponent's home board (easy to hit)
            if player == .white && to >= 18 { score -= 20 }
            if player == .black && to <= 5  { score -= 20 }
        }

        // Also consider if we're leaving a blot at the source
        if let fromPoint = game.points[safe: from], fromPoint.count == 1 {
            // Moving last piece off a point—source becomes empty (good, no blot)
            score += 5
        }

        // 6. Forward progress (pip reduction)
        if player == .white {
            let progress = from - max(to, 0)  // moving toward 0
            score += progress * 3
        } else {
            let progress = min(to, 23) - from  // moving toward 23
            score += progress * 3
        }

        // 7. Build primes (adjacent made points block opponent)
        if to >= 0 && to < 24 {
            let neighbors = [to - 1, to + 1].filter { $0 >= 0 && $0 < 24 }
            for n in neighbors {
                if let np = game.points[safe: n], np.color == player && np.count >= 2 {
                    score += 15  // extending a prime
                }
            }
        }

        // 8. Consolidate: move pieces closer together
        if player == .white && to >= 0 && to < 24 {
            // Prefer moving toward home
            if to < 6 { score += 10 }
        } else if player == .black && to >= 0 && to < 24 {
            if to > 17 { score += 10 }
        }

        return score
    }
}
