import Foundation
import SwiftUI

@Observable final class PebbleGame {
    var board = MancalaBoard()
    var isAnimating = false
    var lastMove: Int? = nil
    var extraTurnMessage: String? = nil
    var difficulty: Int = 1
    var humanPlayer: Int = 0   // 0 = bottom row
    var aiPlayer: Int = 1

    var isHumanTurn: Bool {
        board.currentPlayer == humanPlayer && !board.isGameOver
    }

    var message: String {
        if board.isGameOver {
            if let w = board.winner {
                return w == humanPlayer ? "You win! 🎉" : "AI wins!"
            }
            return "It's a draw!"
        }
        if let msg = extraTurnMessage { return msg }
        return board.currentPlayer == humanPlayer ? "Your turn" : "AI is thinking…"
    }

    func newGame(stonesPerPit: Int = 4) {
        board = MancalaBoard(stonesPerPit: stonesPerPit)
        lastMove = nil
        extraTurnMessage = nil
        isAnimating = false
        // If AI is supposed to move first, trigger it.
        if board.currentPlayer == aiPlayer {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                await aiMove()
            }
        }
    }

    func humanTap(pit: Int) {
        guard isHumanTurn, !isAnimating else { return }
        guard board.validMoves(for: humanPlayer).contains(pit) else { return }
        isAnimating = true
        lastMove = pit
        let extra = board.sow(pit: pit)
        if extra && !board.isGameOver {
            extraTurnMessage = "Extra turn!"
            isAnimating = false
        } else {
            extraTurnMessage = nil
            isAnimating = false
            if !board.isGameOver && board.currentPlayer == aiPlayer {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(700))
                    await aiMove()
                }
            }
        }
    }

    @MainActor
    private func aiMove() async {
        guard !board.isGameOver else { return }
        isAnimating = true
        let move = MancalaAI.bestMove(board: board, difficulty: difficulty)
        guard move >= 0 else { isAnimating = false; return }
        lastMove = move
        let extra = board.sow(pit: move)
        isAnimating = false
        if extra && !board.isGameOver {
            extraTurnMessage = "AI extra turn!"
            try? await Task.sleep(for: .milliseconds(900))
            extraTurnMessage = nil
            await aiMove()
        } else {
            extraTurnMessage = nil
        }
    }
}
