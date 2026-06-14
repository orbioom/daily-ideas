import Foundation

/// Theme tags for tactics puzzles.
enum PuzzleTheme: String, CaseIterable, Identifiable, Codable {
    case backRank = "Back-rank mate"
    case queenMate = "Queen mate"
    case rookMate = "Rook mate"
    case fork = "Fork"
    case pin = "Pin"
    case skewer = "Skewer"
    case discovered = "Discovered attack"
    case promotion = "Promotion"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .backRank: return "rectangle.compress.vertical"
        case .queenMate: return "crown"
        case .rookMate: return "checkerboard.rectangle"
        case .fork: return "arrow.triangle.branch"
        case .pin: return "pin"
        case .skewer: return "arrow.left.and.right"
        case .discovered: return "eye"
        case .promotion: return "arrow.up.circle"
        }
    }
}

/// How a puzzle is validated.
enum PuzzleSolution: Codable, Equatable, Hashable {
    /// Any move that delivers checkmate to the opponent is correct (engine-validated).
    case anyMate
    /// An exact line of UCI moves the user must follow (opponent replies auto-played).
    case moves([String])
}

/// A single tactics puzzle.
struct Puzzle: Identifiable, Equatable, Hashable {
    let id: Int
    let fen: String
    let theme: PuzzleTheme
    let difficultyRating: Int      // ~ Elo flavor for sorting/labeling
    let solution: PuzzleSolution
    let prompt: String             // e.g. "White to move. Mate in one."

    /// The starting board (falls back to the standard position if FEN is malformed).
    var board: Board {
        Board(fen: fen) ?? Board.standard
    }

    /// Side that must find the move.
    var sideToMove: PieceColor {
        board.sideToMove
    }

    var difficultyLabel: String {
        switch difficultyRating {
        case ..<1000: return "Beginner"
        case 1000..<1400: return "Easy"
        case 1400..<1800: return "Intermediate"
        default: return "Hard"
        }
    }
}

/// Result of checking a user's move against a puzzle.
enum PuzzleMoveResult: Equatable {
    case correctAndComplete            // puzzle solved
    case correctContinue(reply: Move?) // right move; opponent reply (if any) to auto-play
    case incorrect
}

extension Puzzle {
    /// Validate a user move. For `.anyMate`, correct iff the move legally delivers mate.
    /// For `.moves`, correct iff it matches the next expected move; returns the opponent's
    /// scripted reply to auto-play, and reports completion at the end of the line.
    func evaluate(userMove: Move, movesPlayedSoFar: Int) -> PuzzleMoveResult {
        switch solution {
        case .anyMate:
            guard let next = board.makeMove(userMove) else { return .incorrect }
            // The opponent is now to move; if they have no legal move and are in check → mate.
            if next.kingInCheck(color: next.sideToMove) && next.legalMoves().isEmpty {
                return .correctAndComplete
            }
            return .incorrect

        case .moves(let line):
            // movesPlayedSoFar counts user+opponent half-moves already applied to the start board.
            guard movesPlayedSoFar < line.count else { return .incorrect }
            let expectedUCI = line[movesPlayedSoFar]
            guard userMove.uci == expectedUCI else { return .incorrect }

            // Index of the opponent reply (if the line continues).
            let replyIndex = movesPlayedSoFar + 1
            if replyIndex < line.count, let reply = Move(uci: line[replyIndex]) {
                return .correctContinue(reply: reply)
            }
            return .correctAndComplete
        }
    }

    /// The from-square to highlight for a hint.
    var hintFromSquare: Square? {
        switch solution {
        case .anyMate:
            // Find a mating move via the engine and reveal its origin.
            for move in board.legalMoves() {
                let next = board.applyingUnchecked(move)
                if next.kingInCheck(color: next.sideToMove) && next.legalMoves().isEmpty {
                    return move.from
                }
            }
            return nil
        case .moves(let line):
            guard let first = line.first, let move = Move(uci: first) else { return nil }
            return move.from
        }
    }

    /// A fully-worked first solution move (for "show solution").
    var solutionFirstMove: Move? {
        switch solution {
        case .anyMate:
            for move in board.legalMoves() {
                let next = board.applyingUnchecked(move)
                if next.kingInCheck(color: next.sideToMove) && next.legalMoves().isEmpty {
                    return move
                }
            }
            return nil
        case .moves(let line):
            guard let first = line.first else { return nil }
            return Move(uci: first)
        }
    }
}
