import Foundation
import SwiftUI

/// Drives a single puzzle attempt: tracks the working board, validates user moves,
/// auto-plays scripted opponent replies, and exposes hint/solution state.
@MainActor
final class PuzzleViewModel: ObservableObject {
    let puzzle: Puzzle

    @Published private(set) var board: Board
    @Published private(set) var lastMove: Move?
    @Published private(set) var solved = false
    @Published private(set) var showWrong = false
    @Published private(set) var hintSquare: Square?
    @Published private(set) var attempts = 0
    @Published private(set) var hintsUsed = 0
    /// How many half-moves of the scripted line have been applied.
    @Published private(set) var movesApplied = 0
    @Published private(set) var revealedSolution = false

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.board = puzzle.board
    }

    var sideToMove: PieceColor { board.sideToMove }
    var isComplete: Bool { solved }

    func legalDestinations(from square: Square) -> [Move] {
        guard !solved else { return [] }
        return board.legalMoves(from: square)
    }

    /// Process a user move; returns true when the move was accepted (correct).
    @discardableResult
    func submit(from: Square, to: Square, promotion: PieceType? = nil) -> Bool {
        guard !solved else { return false }
        showWrong = false

        // Build the candidate move; if a pawn reaches last rank and no promotion was given,
        // default to queen (the puzzle UI presents a picker for explicit choice).
        var move = Move(from: from, to: to, promotion: promotion)
        if promotion == nil, let p = board.piece(at: from), p.type == .pawn {
            let promoRank = p.color == .white ? 7 : 0
            if to.rank == promoRank { move = Move(from: from, to: to, promotion: .queen) }
        }

        let result = puzzle.evaluate(userMove: move, movesPlayedSoFar: movesApplied)
        switch result {
        case .incorrect:
            attempts += 1
            showWrong = true
            return false

        case .correctAndComplete:
            applyUser(move)
            solved = true
            return true

        case .correctContinue(let reply):
            applyUser(move)
            if let reply { applyOpponent(reply) }
            // After the opponent reply, check whether the line is finished.
            if case .moves(let line) = puzzle.solution, movesApplied >= line.count {
                solved = true
            }
            return true
        }
    }

    /// Detect whether a from/to is a promotion that needs a picker.
    func isPromotion(from: Square, to: Square) -> Bool {
        guard let p = board.piece(at: from), p.type == .pawn else { return false }
        let promoRank = p.color == .white ? 7 : 0
        return to.rank == promoRank && board.legalMoves(from: from).contains { $0.to == to }
    }

    private func applyUser(_ move: Move) {
        if let next = board.makeMove(move) {
            board = next
            lastMove = move
            movesApplied += 1
        }
    }

    private func applyOpponent(_ move: Move) {
        if let next = board.makeMove(move) {
            board = next
            lastMove = move
            movesApplied += 1
        }
    }

    func requestHint() {
        hintsUsed += 1
        hintSquare = puzzle.hintFromSquare
    }

    func clearHint() { hintSquare = nil }

    /// Auto-play the full solution (marks the puzzle as shown, not "solved" for streaks).
    func revealSolution() {
        revealedSolution = true
        switch puzzle.solution {
        case .anyMate:
            if let m = puzzle.solutionFirstMove {
                applyUser(m)
                solved = true
            }
        case .moves(let line):
            // Replay the remaining scripted moves.
            for i in movesApplied..<line.count {
                guard i < line.count, let m = Move(uci: line[i]) else { break }
                applyUser(m)
            }
            solved = true
        }
    }

    func reset() {
        board = puzzle.board
        lastMove = nil
        solved = false
        showWrong = false
        hintSquare = nil
        movesApplied = 0
        revealedSolution = false
    }
}
