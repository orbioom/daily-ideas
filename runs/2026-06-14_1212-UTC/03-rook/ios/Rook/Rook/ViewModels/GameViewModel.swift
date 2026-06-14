import Foundation
import SwiftUI

/// Drives a single game: maintains the board derived from a move history, applies user and
/// AI moves, tracks status, and exposes everything the Play screen needs.
@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var board: Board
    @Published private(set) var history: [Move] = []
    @Published private(set) var status: GameStatus = .ongoing
    @Published private(set) var isThinking = false
    @Published private(set) var lastMove: Move?

    /// Pending promotion: a user move whose promotion piece still needs choosing.
    @Published var pendingPromotion: (from: Square, to: Square)?

    let startFEN: String
    var vsComputer: Bool
    var humanSide: HumanSide
    var level: AILevel

    /// Position keys after each ply, for threefold detection.
    private var positionKeys: [String] = []

    init(startFEN: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
         moves: [String] = [],
         vsComputer: Bool = true,
         humanSide: HumanSide = .white,
         level: AILevel = .medium) {
        self.startFEN = startFEN
        self.vsComputer = vsComputer
        self.humanSide = humanSide
        self.level = level
        let base = Board(fen: startFEN) ?? Board.standard
        self.board = base
        self.positionKeys = [base.repetitionKey]
        // Replay any saved moves.
        for uci in moves {
            if let m = Move(uci: uci), let next = board.makeMove(m) {
                board = next
                history.append(m)
                lastMove = m
                positionKeys.append(next.repetitionKey)
            }
        }
        refreshStatus()
    }

    // MARK: - Derived state

    var sideToMove: PieceColor { board.sideToMove }

    var isHumanTurn: Bool {
        if !vsComputer { return true }
        return board.sideToMove == humanSide.color
    }

    var movesUCI: String { history.map { $0.uci }.joined(separator: " ") }

    var isGameOver: Bool { status.isTerminal }

    /// Result from the human's perspective (for records).
    var humanResult: GameResultKind {
        switch status {
        case .checkmate(let winner):
            if !vsComputer { return winner == .white ? .win : .loss } // pass-and-play: store white POV
            return winner == humanSide.color ? .win : .loss
        case .stalemate, .insufficientMaterial, .fiftyMoveRule, .threefold:
            return .draw
        default:
            return .inProgress
        }
    }

    var checkSquare: Square? {
        if board.kingInCheck(color: board.sideToMove) {
            return board.kingSquare(of: board.sideToMove)
        }
        return nil
    }

    // MARK: - Move entry

    func legalDestinations(from square: Square) -> [Move] {
        guard !isGameOver else { return [] }
        return board.legalMoves(from: square)
    }

    /// Attempt a user move from→to. If it's a promotion, stash it and return `.needsPromotion`.
    enum MoveOutcome { case applied(captured: Bool), needsPromotion, illegal }

    func attemptUserMove(from: Square, to: Square) -> MoveOutcome {
        guard isHumanTurn, !isGameOver else { return .illegal }
        // Detect promotion: a pawn reaching the last rank.
        if let p = board.piece(at: from), p.type == .pawn {
            let promoRank = p.color == .white ? 7 : 0
            if to.rank == promoRank,
               board.legalMoves(from: from).contains(where: { $0.to == to }) {
                pendingPromotion = (from, to)
                return .needsPromotion
            }
        }
        let move = Move(from: from, to: to)
        return apply(move)
    }

    /// Finish a stashed promotion with the chosen piece.
    func completePromotion(_ piece: PieceType) -> MoveOutcome {
        guard let pending = pendingPromotion else { return .illegal }
        pendingPromotion = nil
        let move = Move(from: pending.from, to: pending.to, promotion: piece)
        return apply(move)
    }

    func cancelPromotion() { pendingPromotion = nil }

    @discardableResult
    private func apply(_ move: Move) -> MoveOutcome {
        let captured = board.piece(at: move.to) != nil ||
            (board.piece(at: move.from)?.type == .pawn && move.to == board.enPassant)
        guard let next = board.makeMove(move) else { return .illegal }
        board = next
        history.append(move)
        lastMove = move
        positionKeys.append(next.repetitionKey)
        refreshStatus()
        return .applied(captured: captured)
    }

    // MARK: - AI

    /// Compute the AI move off the main thread and apply it.
    func makeAIMoveIfNeeded() async {
        guard vsComputer, !isGameOver, board.sideToMove != humanSide.color else { return }
        guard !isThinking else { return }
        isThinking = true
        let snapshot = board
        let lvl = level
        // Search on a background task; Board is a value type so this is safe.
        let best: Move? = await Task.detached(priority: .userInitiated) {
            ChessAI(level: lvl).bestMove(for: snapshot)
        }.value
        isThinking = false
        if let best, board == snapshot {
            apply(best)
        }
    }

    // MARK: - Controls

    /// Undo the last ply (or two plies when playing the computer, to return to the human).
    func undo() {
        guard !history.isEmpty else { return }
        var plies = 1
        if vsComputer, history.count >= 2, board.sideToMove == humanSide.color {
            // Undo the AI reply and our move so it's our turn again.
            plies = 2
        }
        for _ in 0..<plies where !history.isEmpty {
            history.removeLast()
            if positionKeys.count > 1 { positionKeys.removeLast() }
        }
        rebuild()
    }

    func resign() {
        // Human resigns: opponent wins.
        let winner = humanSide.color.opposite
        status = .checkmate(winner: winner)
    }

    func newGame(vsComputer: Bool, humanSide: HumanSide, level: AILevel) {
        self.vsComputer = vsComputer
        self.humanSide = humanSide
        self.level = level
        let base = Board(fen: startFEN) ?? Board.standard
        board = base
        history = []
        lastMove = nil
        positionKeys = [base.repetitionKey]
        pendingPromotion = nil
        refreshStatus()
    }

    /// Reset configuration and replay a saved move list (for resuming a game).
    func load(moves: [String], vsComputer: Bool, humanSide: HumanSide, level: AILevel, result: GameResultKind) {
        newGame(vsComputer: vsComputer, humanSide: humanSide, level: level)
        for uci in moves {
            guard let m = Move(uci: uci), let next = board.makeMove(m) else { continue }
            board = next
            history.append(m)
            lastMove = m
            positionKeys.append(next.repetitionKey)
        }
        refreshStatus()
        // If the saved game was already resigned/finished, reflect that.
        if result != .inProgress, !status.isTerminal {
            // Preserve a recorded non-terminal result (e.g. resignation) only for display;
            // ongoing engine status governs further play.
        }
    }

    private func rebuild() {
        var b = Board(fen: startFEN) ?? Board.standard
        positionKeys = [b.repetitionKey]
        for m in history {
            if let next = b.makeMove(m) { b = next; positionKeys.append(next.repetitionKey) }
        }
        board = b
        lastMove = history.last
        refreshStatus()
    }

    private func refreshStatus() {
        status = board.status(repetitionFENs: positionKeys)
    }
}
