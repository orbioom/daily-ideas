import Foundation

enum DropAI {
    static func bestMove(grid: [[DropCell]], depth: Int) -> Int {
        let cols = DropGame.cols
        var bestCol = cols / 2
        var bestScore = Int.min

        // Prioritize center, then outer columns for move ordering
        let orderedCols = [3, 2, 4, 1, 5, 0, 6]

        for col in orderedCols where col < cols {
            if let row = availableRow(grid: grid, col: col) {
                var g = grid
                g[row][col] = .cpu
                let score = minimax(
                    grid: g,
                    depth: depth - 1,
                    alpha: Int.min + 1,
                    beta: Int.max - 1,
                    maximizing: false
                )
                if score > bestScore {
                    bestScore = score
                    bestCol = col
                }
            }
        }
        return bestCol
    }

    private static func minimax(
        grid: [[DropCell]],
        depth: Int,
        alpha: Int,
        beta: Int,
        maximizing: Bool
    ) -> Int {
        let score = evaluate(grid: grid)
        if score >= 100_000 || score <= -100_000 { return score }

        let filled = grid.flatMap { $0 }.filter { $0 != .empty }.count
        if filled == DropGame.cols * DropGame.rows { return 0 }

        if depth == 0 { return score }

        var alpha = alpha
        var beta = beta
        let orderedCols = [3, 2, 4, 1, 5, 0, 6]

        if maximizing {
            var best = Int.min + 1
            for col in orderedCols where col < DropGame.cols {
                if let row = availableRow(grid: grid, col: col) {
                    var g = grid
                    g[row][col] = .cpu
                    let val = minimax(grid: g, depth: depth - 1, alpha: alpha, beta: beta, maximizing: false)
                    best = max(best, val)
                    alpha = max(alpha, best)
                    if beta <= alpha { break }
                }
            }
            return best
        } else {
            var best = Int.max - 1
            for col in orderedCols where col < DropGame.cols {
                if let row = availableRow(grid: grid, col: col) {
                    var g = grid
                    g[row][col] = .human
                    let val = minimax(grid: g, depth: depth - 1, alpha: alpha, beta: beta, maximizing: true)
                    best = min(best, val)
                    beta = min(beta, best)
                    if beta <= alpha { break }
                }
            }
            return best
        }
    }

    private static func availableRow(grid: [[DropCell]], col: Int) -> Int? {
        for row in stride(from: DropGame.rows - 1, through: 0, by: -1) {
            if grid[row][col] == .empty { return row }
        }
        return nil
    }

    private static func evaluate(grid: [[DropCell]]) -> Int {
        var score = 0
        let rows = DropGame.rows
        let cols = DropGame.cols

        // Evaluate all windows of 4
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        for r in 0..<rows {
            for c in 0..<cols {
                for (dr, dc) in directions {
                    var humanCount = 0
                    var cpuCount = 0
                    var valid = true

                    for i in 0..<4 {
                        let nr = r + i * dr
                        let nc = c + i * dc
                        guard nr >= 0 && nr < rows && nc >= 0 && nc < cols else {
                            valid = false
                            break
                        }
                        switch grid[nr][nc] {
                        case .human: humanCount += 1
                        case .cpu: cpuCount += 1
                        case .empty: break
                        }
                    }

                    guard valid else { continue }

                    if cpuCount == 4 { return 1_000_000 }
                    if humanCount == 4 { return -1_000_000 }

                    if humanCount == 0 {
                        score += windowScore(count: cpuCount)
                    }
                    if cpuCount == 0 {
                        score -= windowScore(count: humanCount)
                    }
                }
            }
        }

        // Center column preference
        let centerCol = cols / 2
        for r in 0..<rows {
            if grid[r][centerCol] == .cpu { score += 3 }
            if grid[r][centerCol] == .human { score -= 3 }
        }

        // Prefer lower rows (more stable positions)
        for r in 0..<rows {
            for c in 0..<cols {
                let rowBonus = (rows - r)
                if grid[r][c] == .cpu { score += rowBonus / 2 }
                if grid[r][c] == .human { score -= rowBonus / 2 }
            }
        }

        return score
    }

    private static func windowScore(_ count: Int) -> Int {
        switch count {
        case 3: return 100
        case 2: return 10
        case 1: return 1
        default: return 0
        }
    }
}
