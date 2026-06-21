import Foundation
import SwiftUI

@Observable
@MainActor
final class GomokuEngine {
    enum Stone: String { case black, white }
    enum GamePhase { case playing, won(Stone), draw }

    static let size = 15

    private(set) var board: [[Stone?]]
    private(set) var phase: GamePhase = .playing
    private(set) var lastMove: (row: Int, col: Int)?
    private(set) var moveCount: Int = 0
    private(set) var isThinking: Bool = false
    private(set) var startDate: Date = Date()
    private(set) var winningCells: Set<String> = []

    var humanStone: Stone = .black
    var difficulty: String = "Normal"

    private var aiStone: Stone { humanStone == .black ? .white : .black }

    init() {
        board = Array(repeating: Array(repeating: nil, count: Self.size), count: Self.size)
    }

    func reset(humanColor: String, difficulty: String) {
        board = Array(repeating: Array(repeating: nil, count: Self.size), count: Self.size)
        phase = .playing
        lastMove = nil
        moveCount = 0
        isThinking = false
        startDate = Date()
        winningCells = []
        self.humanStone = humanColor == "Black" ? .black : .white
        self.difficulty = difficulty

        // If AI goes first (human is White), AI moves immediately
        if humanStone == .white {
            Task { await makeAIMove() }
        }
    }

    func handleTap(row: Int, col: Int) {
        guard case .playing = phase,
              board[row][col] == nil,
              !isThinking else { return }
        guard row >= 0, row < Self.size, col >= 0, col < Self.size else { return }

        place(stone: humanStone, row: row, col: col)

        guard case .playing = phase else { return }
        Task { await makeAIMove() }
    }

    var elapsedSeconds: Int {
        if case .playing = phase {
            return Int(Date().timeIntervalSince(startDate))
        }
        return Int(Date().timeIntervalSince(startDate))
    }

    // MARK: - Private

    private func place(stone: Stone, row: Int, col: Int) {
        board[row][col] = stone
        lastMove = (row, col)
        moveCount += 1
        if let cells = checkWin(stone: stone, row: row, col: col) {
            winningCells = cells
            phase = .won(stone)
        } else if moveCount == Self.size * Self.size {
            phase = .draw
        }
    }

    private func makeAIMove() async {
        guard case .playing = phase else { return }
        isThinking = true
        let boardCopy = board
        let stone = aiStone
        let diff = difficulty

        let move = await Task.detached(priority: .userInitiated) { [boardCopy, stone, diff] in
            GomokuEngine.computeBestMove(board: boardCopy, stone: stone, difficulty: diff)
        }.value

        isThinking = false
        guard case .playing = phase else { return }
        place(stone: stone, row: move.row, col: move.col)
    }

    private func checkWin(stone: Stone, row: Int, col: Int) -> Set<String>? {
        let dirs: [(Int, Int)] = [(0,1),(1,0),(1,1),(1,-1)]
        for (dr, dc) in dirs {
            var cells: [(Int,Int)] = [(row, col)]
            for sign in [-1, 1] {
                var r = row + sign * dr, c = col + sign * dc
                while r >= 0, r < Self.size, c >= 0, c < Self.size, board[r][c] == stone {
                    cells.append((r, c))
                    r += sign * dr; c += sign * dc
                }
            }
            if cells.count >= 5 {
                return Set(cells.map { "\($0.0),\($0.1)" })
            }
        }
        return nil
    }

    // MARK: - AI

    static func computeBestMove(board: [[Stone?]], stone: Stone, difficulty: String) -> (row: Int, col: Int) {
        let opponent: Stone = stone == .black ? .white : .black
        let candidates = candidateMoves(board: board)

        // Immediate win
        for pos in candidates {
            var b = board
            b[pos.row][pos.col] = stone
            if quickWin(board: b, stone: stone, row: pos.row, col: pos.col) {
                return pos
            }
        }

        // Block immediate opponent win
        for pos in candidates {
            var b = board
            b[pos.row][pos.col] = opponent
            if quickWin(board: b, stone: opponent, row: pos.row, col: pos.col) {
                return pos
            }
        }

        if difficulty == "Easy" {
            // Random from candidates, picking near existing stones
            return candidates.randomElement() ?? findFirstEmpty(board: board)
        }

        // Score each candidate
        var best: (row: Int, col: Int) = candidates.first ?? (7, 7)
        var bestScore = Int.min

        for pos in candidates {
            let offScore = evaluateMove(board: board, stone: stone, row: pos.row, col: pos.col)
            let defScore = evaluateMove(board: board, stone: opponent, row: pos.row, col: pos.col)
            let score = offScore + (difficulty == "Hard" ? defScore : defScore / 2)
            if score > bestScore {
                bestScore = score
                best = pos
            }
        }
        return best
    }

    private static func candidateMoves(board: [[Stone?]]) -> [(row: Int, col: Int)] {
        var seen = Set<String>()
        var result: [(row: Int, col: Int)] = []
        var hasAny = false
        for r in 0..<size {
            for c in 0..<size where board[r][c] != nil {
                hasAny = true
                for dr in -2...2 {
                    for dc in -2...2 where !(dr == 0 && dc == 0) {
                        let nr = r + dr, nc = c + dc
                        guard nr >= 0, nr < size, nc >= 0, nc < size else { continue }
                        guard board[nr][nc] == nil else { continue }
                        let key = "\(nr),\(nc)"
                        guard !seen.contains(key) else { continue }
                        seen.insert(key)
                        result.append((nr, nc))
                    }
                }
            }
        }
        if !hasAny { return [(7, 7)] }
        return result
    }

    private static func findFirstEmpty(board: [[Stone?]]) -> (row: Int, col: Int) {
        for r in 0..<size {
            for c in 0..<size where board[r][c] == nil {
                return (r, c)
            }
        }
        return (0, 0)
    }

    private static func quickWin(board: [[Stone?]], stone: Stone, row: Int, col: Int) -> Bool {
        let dirs: [(Int,Int)] = [(0,1),(1,0),(1,1),(1,-1)]
        for (dr, dc) in dirs {
            var count = 1
            for sign in [-1, 1] {
                var r = row + sign * dr, c = col + sign * dc
                while r >= 0, r < size, c >= 0, c < size, board[r][c] == stone {
                    count += 1; r += sign * dr; c += sign * dc
                }
            }
            if count >= 5 { return true }
        }
        return false
    }

    private static func evaluateMove(board: [[Stone?]], stone: Stone, row: Int, col: Int) -> Int {
        var b = board
        b[row][col] = stone
        let dirs: [(Int,Int)] = [(0,1),(1,0),(1,1),(1,-1)]
        var total = 0
        for (dr, dc) in dirs {
            var count = 1
            var openEnds = 0
            for sign in [-1, 1] {
                var r = row + sign * dr, c = col + sign * dc
                while r >= 0, r < size, c >= 0, c < size, b[r][c] == stone {
                    count += 1; r += sign * dr; c += sign * dc
                }
                if r >= 0, r < size, c >= 0, c < size, b[r][c] == nil { openEnds += 1 }
            }
            total += patternScore(count: count, openEnds: openEnds)
        }
        return total
    }

    private static func patternScore(count: Int, openEnds: Int) -> Int {
        switch (count, openEnds) {
        case (5..., _): return 1_000_000
        case (4, 2): return 100_000
        case (4, 1): return 10_000
        case (3, 2): return 5_000
        case (3, 1): return 1_000
        case (2, 2): return 200
        case (2, 1): return 50
        default: return 0
        }
    }
}
