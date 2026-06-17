import Foundation
import SwiftData

/// Seeds a PuzzleProgress row for every bundled puzzle once, so Levels / Stats
/// have stable rows to query and update. Idempotent — checks a count first.
enum SeedData {

    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<PuzzleProgress>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for puzzle in PuzzleBank.all {
            let row = PuzzleProgress(
                puzzleId: puzzle.id,
                packRaw: puzzle.packId.rawValue,
                size: puzzle.size,
                solved: false,
                perfect: false,
                bestMoves: 0,
                bestSeconds: 0,
                lastPlayed: .distantPast
            )
            context.insert(row)
        }
        try? context.save()
    }
}
