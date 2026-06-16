import Foundation
import SwiftData

/// Seeds a realistic spread of completed puzzles and daily results so Stats and the
/// library look alive immediately. Guarded by a one-time flag and an empty-store check so
/// it never duplicates or overwrites real play. Produces 50+ items overall.
enum SeedData {
    private static let seededKey = "didSeedLimnHistory"

    /// Seeds on first launch only (called from RootView).
    static func seedIfNeeded(context: ModelContext) {
        if UserDefaults.standard.bool(forKey: seededKey) { return }

        let recordDescriptor = FetchDescriptor<PuzzleRecord>()
        let existing = (try? context.fetch(recordDescriptor)) ?? []
        guard existing.isEmpty else {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        insertSampleData(context: context)
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// Inserts sample data on demand (Settings → Load sample data). Skips ids that
    /// already exist so it is safe to run alongside real progress.
    static func insertSampleData(context: ModelContext) {
        let existingRecords = (try? context.fetch(FetchDescriptor<PuzzleRecord>())) ?? []
        let existingRecordIDs = Set(existingRecords.map(\.puzzleID))
        for record in makeRecords() where !existingRecordIDs.contains(record.puzzleID) {
            context.insert(record)
        }

        let existingDailies = (try? context.fetch(FetchDescriptor<DailyResult>())) ?? []
        let existingDailyKeys = Set(existingDailies.map(\.dateKey))
        for daily in makeDailyResults() where !existingDailyKeys.contains(daily.dateKey) {
            context.insert(daily)
        }

        try? context.save()
    }

    /// Marks roughly two-thirds of the bank as solved, with believable times & mistakes.
    static func makeRecords() -> [PuzzleRecord] {
        var rng = SplitMix64(seed: 0x11_B0_0B_5)
        var records: [PuzzleRecord] = []
        let now = Date()

        for (offset, puzzle) in PuzzleBank.allPuzzles.enumerated() {
            // Solve about 70% of puzzles deterministically.
            let solveRoll = rng.next() % 10
            let completed = solveRoll < 7
            guard completed else { continue }

            // Time scales with grid area, plus jitter.
            let area = puzzle.rows * puzzle.cols
            let base = area * 2
            let jitter = Int(rng.next() % UInt64(max(area, 1)))
            let time = max(20, base + jitter)
            let mistakes = Int(rng.next() % 4)
            let daysAgo = (offset * 2) % 56
            let date = now.addingTimeInterval(TimeInterval(-daysAgo * 86_400))

            records.append(PuzzleRecord(
                puzzleID: puzzle.id,
                bestTimeSeconds: time,
                completedDate: date,
                mistakes: mistakes,
                completed: true
            ))
        }
        return records
    }

    /// Builds ~24 days of daily results ending today, with a couple of skipped days so the
    /// streak reads realistically.
    static func makeDailyResults(now: Date = Date(), calendar: Calendar = .current) -> [DailyResult] {
        var rng = SplitMix64(seed: 0xDA11_5EED)
        var results: [DailyResult] = []
        let skipDays: Set<Int> = [9, 15, 16] // gaps in the streak

        for daysAgo in 0..<24 {
            if skipDays.contains(daysAgo) { continue }
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            let puzzle = PuzzleBank.dailyPuzzle(for: day, calendar: calendar)
            let area = puzzle.rows * puzzle.cols
            let time = max(20, area * 2 + Int(rng.next() % UInt64(max(area, 1))))
            let mistakes = Int(rng.next() % 3)
            results.append(DailyResult(
                dateKey: DateKey.string(for: day, calendar: calendar),
                puzzleID: puzzle.id,
                completed: true,
                timeSeconds: time,
                mistakes: mistakes
            ))
        }
        return results
    }
}
