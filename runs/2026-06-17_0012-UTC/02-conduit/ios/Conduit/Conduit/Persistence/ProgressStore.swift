import Foundation
import SwiftData

/// Convenience read/write helpers over the SwiftData stores. Kept free of UI so it
/// can be called from views with a `ModelContext`. All failures are swallowed
/// gracefully (never throw to the UI) — the worst case is a missed stat update.
enum ProgressStore {

    // MARK: - Per-puzzle progress

    static func progress(for puzzleId: String, in context: ModelContext) -> PuzzleProgress? {
        var descriptor = FetchDescriptor<PuzzleProgress>(
            predicate: #Predicate { $0.puzzleId == puzzleId }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Record a completed solve, keeping best move/time records.
    static func recordSolve(
        puzzle: Puzzle,
        moves: Int,
        seconds: Int,
        perfect: Bool,
        in context: ModelContext
    ) {
        let row: PuzzleProgress
        if let existing = progress(for: puzzle.id, in: context) {
            row = existing
        } else {
            row = PuzzleProgress(
                puzzleId: puzzle.id,
                packRaw: puzzle.packId.rawValue,
                size: puzzle.size
            )
            context.insert(row)
        }
        row.solved = true
        if perfect { row.perfect = true }
        if row.bestMoves == 0 || moves < row.bestMoves { row.bestMoves = max(1, moves) }
        if row.bestSeconds == 0 || (seconds > 0 && seconds < row.bestSeconds) {
            row.bestSeconds = max(1, seconds)
        }
        row.lastPlayed = .now
        try? context.save()
    }

    static func markPlayed(puzzle: Puzzle, in context: ModelContext) {
        if let row = progress(for: puzzle.id, in: context) {
            row.lastPlayed = .now
        } else {
            let row = PuzzleProgress(puzzleId: puzzle.id, packRaw: puzzle.packId.rawValue, size: puzzle.size)
            context.insert(row)
        }
        try? context.save()
    }

    // MARK: - Saved board (single in-progress board)

    static func loadSavedBoard(in context: ModelContext) -> SavedBoard? {
        var descriptor = FetchDescriptor<SavedBoard>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    static func saveBoard(
        puzzleId: String,
        paths: [PipeColor: [Cell]],
        elapsed: Int,
        moves: Int,
        in context: ModelContext
    ) {
        clearSavedBoards(in: context)
        let json = SavedPaths(from: paths).jsonString()
        let board = SavedBoard(puzzleId: puzzleId, pathsJSON: json, elapsedSeconds: max(0, elapsed), moveCount: max(0, moves))
        context.insert(board)
        try? context.save()
    }

    static func clearSavedBoards(in context: ModelContext) {
        let descriptor = FetchDescriptor<SavedBoard>()
        if let boards = try? context.fetch(descriptor) {
            for board in boards { context.delete(board) }
            try? context.save()
        }
    }

    // MARK: - Daily results

    static func dailyResult(dayKey: String, in context: ModelContext) -> DailyResult? {
        var descriptor = FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.dayKey == dayKey }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    static func recordDaily(
        dayKey: String,
        puzzleId: String,
        seconds: Int,
        perfect: Bool,
        in context: ModelContext
    ) {
        if let existing = dailyResult(dayKey: dayKey, in: context) {
            existing.solved = true
            if perfect { existing.perfect = true }
            if seconds > 0 && (existing.seconds == 0 || seconds < existing.seconds) {
                existing.seconds = seconds
            }
        } else {
            let result = DailyResult(
                dayKey: dayKey,
                puzzleId: puzzleId,
                solved: true,
                seconds: max(1, seconds),
                perfect: perfect,
                date: .now
            )
            context.insert(result)
        }
        try? context.save()
    }
}
