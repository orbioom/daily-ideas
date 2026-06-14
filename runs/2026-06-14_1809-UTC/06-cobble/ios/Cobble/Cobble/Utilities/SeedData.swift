import Foundation
import SwiftData

/// Seeds ~60 past GameResults (classic + daily, varied scores over ~4 weeks) so Stats and
/// charts are rich on first run. Gated behind the `didSeed` flag. Does NOT seed a SavedGame
/// — a fresh board on first launch is correct.
enum SeedData {

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        insertSampleResults(context: context)
        didSeed = true
    }

    /// Insert ~60 sample results spread over the last 28 days. Deterministic via SplitMix64
    /// so the sample looks consistent. Used by first-run seeding and the Settings action.
    static func insertSampleResults(context: ModelContext) {
        var rng = SplitMix64(seed: 0xC0BB1E5EED)
        let now = Date()
        let cal = Calendar.current

        for i in 0..<60 {
            // Spread across ~28 days, a few per day.
            let dayOffset = i / 2  // 0...29
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let date = day.addingTimeInterval(Double(rng.int(40_000)))

            let isDaily = rng.int(3) == 0
            let mode: GameMode = isDaily ? .daily : .classic

            // Scores trend upward over time (more recent = a bit better), with noise.
            let skill = max(0, 30 - dayOffset)            // 0...30
            let base = 220 + skill * 14
            let noise = rng.int(380) - 120
            let score = max(40, base + noise)

            let pieces = 18 + rng.int(60)
            let lines = max(0, score / 45 + rng.int(6) - 2)
            let combo = rng.int(6)
            let dur = 120 + rng.int(900)
            let dateKey = isDaily ? DailySeed.dateKey(for: day) : ""

            let result = GameResult(date: date,
                                    score: score,
                                    linesCleared: lines,
                                    piecesPlaced: pieces,
                                    longestCombo: combo,
                                    mode: mode,
                                    durationSec: dur,
                                    dateKey: dateKey)
            context.insert(result)

            BestScores.record(score: score, mode: mode, dateKey: dateKey)
        }
        try? context.save()
    }

    /// Delete all GameResults and the active SavedGame, and reset best-score storage.
    static func clearAll(context: ModelContext) {
        if let results = try? context.fetch(FetchDescriptor<GameResult>()) {
            for r in results { context.delete(r) }
        }
        if let saves = try? context.fetch(FetchDescriptor<SavedGame>()) {
            for s in saves { context.delete(s) }
        }
        try? context.save()
        BestScores.reset()
    }

    /// Delete only the stats history (keep any in-progress saved game). For "Reset stats".
    static func clearResults(context: ModelContext) {
        if let results = try? context.fetch(FetchDescriptor<GameResult>()) {
            for r in results { context.delete(r) }
        }
        try? context.save()
        BestScores.reset()
    }
}
