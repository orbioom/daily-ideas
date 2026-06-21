import SwiftUI
import SwiftData

// MARK: - Domain Types
enum Piece: String, Codable {
    case black, white
    var opponent: Piece { self == .black ? .white : .black }
}

struct BoardState {
    var cells: [[Piece?]]
    static func initial() -> BoardState {
        var cells: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        cells[3][3] = .white; cells[3][4] = .black
        cells[4][3] = .black; cells[4][4] = .white
        return BoardState(cells: cells)
    }
    subscript(r: Int, c: Int) -> Piece? {
        get { cells[r][c] }
        set { cells[r][c] = newValue }
    }
    func score() -> (black: Int, white: Int) {
        var b = 0, w = 0
        for row in cells { for cell in row { if cell == .black { b += 1 } else if cell == .white { w += 1 } } }
        return (b, w)
    }
}

// MARK: - Reversi Engine
struct ReversiEngine {
    static let directions = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]

    static func flipped(board: BoardState, row: Int, col: Int, piece: Piece) -> [(Int,Int)] {
        guard board[row,col] == nil else { return [] }
        var result: [(Int,Int)] = []
        for (dr,dc) in directions {
            var line: [(Int,Int)] = []
            var r = row+dr, c = col+dc
            while r >= 0 && r < 8 && c >= 0 && c < 8 {
                if board[r,c] == piece.opponent { line.append((r,c)) }
                else if board[r,c] == piece { result.append(contentsOf: line); break }
                else { break }
                r += dr; c += dc
            }
        }
        return result
    }

    static func validMoves(board: BoardState, for piece: Piece) -> [(Int,Int)] {
        var moves: [(Int,Int)] = []
        for r in 0..<8 { for c in 0..<8 { if !flipped(board: board, row: r, col: c, piece: piece).isEmpty { moves.append((r,c)) } } }
        return moves
    }

    static func apply(board: inout BoardState, row: Int, col: Int, piece: Piece) {
        let toFlip = flipped(board: board, row: row, col: col, piece: piece)
        board[row,col] = piece
        for (r,c) in toFlip { board[r,c] = piece }
    }

    // Position weights for evaluation
    static let weights: [[Int]] = [
        [100,-25,10, 5, 5,10,-25,100],
        [-25,-50,-2,-2,-2,-2,-50,-25],
        [ 10,  -2, 4, 2, 2, 4,  -2, 10],
        [  5,  -2, 2, 1, 1, 2,  -2,  5],
        [  5,  -2, 2, 1, 1, 2,  -2,  5],
        [ 10,  -2, 4, 2, 2, 4,  -2, 10],
        [-25,-50,-2,-2,-2,-2,-50,-25],
        [100,-25,10, 5, 5,10,-25,100]
    ]

    static func evaluate(board: BoardState, for piece: Piece) -> Int {
        var score = 0
        for r in 0..<8 { for c in 0..<8 {
            if board[r,c] == piece { score += weights[r][c] }
            else if board[r,c] == piece.opponent { score -= weights[r][c] }
        }}
        // Mobility bonus
        let myMoves = validMoves(board: board, for: piece).count
        let oppMoves = validMoves(board: board, for: piece.opponent).count
        score += (myMoves - oppMoves) * 5
        return score
    }

    static func minimax(board: BoardState, piece: Piece, depth: Int, alpha: Int, beta: Int, maximizing: Bool) -> Int {
        let moves = validMoves(board: board, for: maximizing ? piece : piece.opponent)
        if depth == 0 || (moves.isEmpty && validMoves(board: board, for: maximizing ? piece.opponent : piece).isEmpty) {
            return evaluate(board: board, for: piece)
        }
        if moves.isEmpty {
            return minimax(board: board, piece: piece, depth: depth-1, alpha: alpha, beta: beta, maximizing: !maximizing)
        }
        var alpha = alpha, beta = beta
        if maximizing {
            var best = Int.min
            for (r,c) in moves {
                var b = board; apply(board: &b, row: r, col: c, piece: piece)
                best = max(best, minimax(board: b, piece: piece, depth: depth-1, alpha: alpha, beta: beta, maximizing: false))
                alpha = max(alpha, best)
                if beta <= alpha { break }
            }
            return best
        } else {
            var best = Int.max
            for (r,c) in moves {
                var b = board; apply(board: &b, row: r, col: c, piece: piece.opponent)
                best = min(best, minimax(board: b, piece: piece, depth: depth-1, alpha: alpha, beta: beta, maximizing: true))
                beta = min(beta, best)
                if beta <= alpha { break }
            }
            return best
        }
    }

    static func bestMove(board: BoardState, for piece: Piece, depth: Int) -> (Int,Int)? {
        let moves = validMoves(board: board, for: piece)
        guard !moves.isEmpty else { return nil }
        var bestScore = Int.min
        var bestMove = moves[0]
        for (r,c) in moves {
            var b = board; apply(board: &b, row: r, col: c, piece: piece)
            let score = minimax(board: b, piece: piece, depth: depth-1, alpha: Int.min, beta: Int.max, maximizing: false)
            if score > bestScore { bestScore = score; bestMove = (r,c) }
        }
        return bestMove
    }
}

// MARK: - GameViewModel
enum GamePhase { case playing, aiThinking, gameOver }

@Observable
final class GameViewModel {
    var board = BoardState.initial()
    var currentTurn: Piece = .black
    var phase: GamePhase = .playing
    var playerPiece: Piece = .black
    var aiDepth: Int = 2
    var showHints: Bool = true
    var animatingFlips: [(Int,Int)] = []
    var lastPlaced: (Int,Int)? = nil
    var startTime: Date = .now

    var validMoves: [(Int,Int)] { ReversiEngine.validMoves(board: board, for: currentTurn) }
    var isPlayerTurn: Bool { currentTurn == playerPiece && phase == .playing }
    var score: (black: Int, white: Int) { board.score() }

    func playerMove(row: Int, col: Int) {
        guard isPlayerTurn, validMoves.contains(where: { $0 == (row,col) }) else { return }
        place(row: row, col: col, piece: playerPiece)
    }

    private func place(row: Int, col: Int, piece: Piece) {
        let flipped = ReversiEngine.flipped(board: board, row: row, col: col, piece: piece)
        ReversiEngine.apply(board: &board, row: row, col: col, piece: piece)
        lastPlaced = (row,col)
        animatingFlips = flipped
        advanceTurn()
    }

    private func advanceTurn() {
        let next = currentTurn.opponent
        if !ReversiEngine.validMoves(board: board, for: next).isEmpty {
            currentTurn = next
            if currentTurn != playerPiece { scheduleAI() }
        } else if !ReversiEngine.validMoves(board: board, for: currentTurn).isEmpty {
            // opponent has no moves, current player goes again
            if currentTurn != playerPiece { scheduleAI() }
        } else {
            phase = .gameOver
        }
    }

    private func scheduleAI() {
        phase = .aiThinking
        let b = board, p = currentTurn, d = aiDepth
        Task.detached(priority: .userInitiated) {
            let move = ReversiEngine.bestMove(board: b, for: p, depth: d)
            await MainActor.run {
                if let (r,c) = move {
                    self.place(row: r, col: c, piece: p)
                } else {
                    self.advanceTurn()
                }
                self.phase = self.validMoves.isEmpty ? .gameOver : .playing
            }
        }
    }

    func newGame(playerPiece: Piece, depth: Int) {
        board = .initial()
        currentTurn = .black
        phase = .playing
        self.playerPiece = playerPiece
        self.aiDepth = depth
        lastPlaced = nil
        animatingFlips = []
        startTime = .now
        if playerPiece == .white {
            scheduleAI()
        }
    }

    var winner: String {
        let s = score
        if s.black > s.white { return "black" }
        if s.white > s.black { return "white" }
        return "draw"
    }

    var durationSeconds: Int { Int(Date.now.timeIntervalSince(startTime)) }
}
