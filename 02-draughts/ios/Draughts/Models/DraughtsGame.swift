import Foundation
import Observation

// MARK: - Game Status

enum GameStatus: Equatable {
    case playing
    case humanWon
    case aiWon
    case draw
}

// MARK: - DraughtsGame

@Observable
final class DraughtsGame {
    var board: CheckersBoard = .initial()
    var selectedCell: (row: Int, col: Int)?
    var highlightedMoves: [CheckersMove] = []
    var gameStatus: GameStatus = .playing
    var difficulty: Difficulty = .medium
    var humanPlayer: Player = .red
    var isAIThinking: Bool = false
    var lastMove: CheckersMove?
    var moveCount: Int = 0

    private let ai = CheckersAI()

    // MARK: - Derived

    var isHumanTurn: Bool {
        board.currentPlayer == humanPlayer && gameStatus == .playing
    }

    var aiPlayer: Player { humanPlayer.opponent }

    // MARK: - New Game

    func newGame(humanPlayer: Player = .red, difficulty: Difficulty = .medium) {
        self.humanPlayer = humanPlayer
        self.difficulty = difficulty
        board = .initial()
        selectedCell = nil
        highlightedMoves = []
        gameStatus = .playing
        lastMove = nil
        moveCount = 0

        // If AI goes first (human plays black), kick off AI move
        if board.currentPlayer == aiPlayer {
            Task { await triggerAIMove() }
        }
    }

    // MARK: - Tap Handler

    func tap(row: Int, col: Int) {
        guard gameStatus == .playing, isHumanTurn else { return }

        // If tapping a highlighted destination, execute the move
        if let move = highlightedMoves.first(where: { $0.to.row == row && $0.to.col == col }) {
            executeMove(move)
            return
        }

        // If tapping a piece belonging to human player, select it
        if let piece = board.cells[row][col], piece.player == humanPlayer {
            selectedCell = (row, col)

            // Compute valid moves for this piece from the full valid move set
            // so that mandatory jump restriction is already applied.
            let allValid = board.validMoves(for: humanPlayer)
            highlightedMoves = allValid.filter { $0.from.row == row && $0.from.col == col }
            return
        }

        // Tapped on empty or opponent cell with nothing selected — deselect
        selectedCell = nil
        highlightedMoves = []
    }

    // MARK: - AI Move

    @MainActor
    func triggerAIMove() async {
        guard gameStatus == .playing, board.currentPlayer == aiPlayer else { return }
        isAIThinking = true

        // Run minimax off the main thread
        let capturedBoard = board
        let capturedDifficulty = difficulty
        let capturedAI = ai

        let move = await Task.detached(priority: .userInitiated) {
            capturedAI.bestMove(for: capturedBoard, difficulty: capturedDifficulty)
        }.value

        isAIThinking = false

        guard let aiMove = move else {
            // AI has no moves — human wins
            updateStatus()
            return
        }

        executeMove(aiMove)
    }

    // MARK: - Private

    private func executeMove(_ move: CheckersMove) {
        board = board.applyMove(move)
        lastMove = move
        moveCount += 1
        selectedCell = nil
        highlightedMoves = []
        updateStatus()

        // If still playing and now AI's turn, trigger AI
        if gameStatus == .playing && board.currentPlayer == aiPlayer {
            Task { await triggerAIMove() }
        }
    }

    private func updateStatus() {
        guard board.isTerminal else { return }

        if let winner = board.winner() {
            gameStatus = winner == humanPlayer ? .humanWon : .aiWon
        } else {
            gameStatus = .draw
        }
    }
}
