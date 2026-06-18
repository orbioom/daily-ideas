import Foundation
import SwiftData

/// Seeds realistic past Daily results on first run so Stats and streaks look alive immediately.
/// Guarded by a flag so it runs exactly once.
enum SeedData {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let flagKey = "didSeedDailyResults"
        if UserDefaults.standard.bool(forKey: flagKey) { return }

        // Build ~32 days of history ending yesterday, with a couple of natural gaps.
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())

        // Deterministic but varied figures via SplitMix64.
        var rng = SplitMix64(seed: 0xC0FFEE_1234_5678)
        let skipOffsets: Set<Int> = [5, 6, 17] // a small slump + a missed day

        for offset in 1...32 {
            if skipOffsets.contains(offset) { continue }
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = DateKey.key(for: day)

            // Pick the seed that would have been the Daily that day to keep maxima realistic.
            let puzzle = PuzzleGenerator.daily(for: key)
            let maxScore = max(puzzle.totalPossibleScore, 1)

            // Performance fraction trends upward over time with noise.
            let recency = Double(33 - offset) / 33.0
            let noise = Double(rng.index(below: 30)) / 100.0
            var fraction = 0.18 + recency * 0.45 + noise - 0.12
            fraction = min(max(fraction, 0.05), 0.95)

            let score = Int((fraction * Double(maxScore)).rounded())
            // Approximate words found from score (most words are ~4-5 letters → ~1-5 pts).
            let words = max(1, Int(Double(score) / 3.2) + rng.index(below: 3))
            let pangrams = fraction > 0.55 ? min(puzzle.pangrams.count, rng.index(below: 2)) : 0
            let reachedGenius = fraction >= Rank.genius.fraction

            let result = DailyResult(
                dateKey: key,
                score: score,
                wordsFound: min(words, puzzle.solutions.count),
                pangrams: pangrams,
                reachedGenius: reachedGenius,
                date: day
            )
            context.insert(result)
        }

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: flagKey)
        } catch {
            // Non-fatal: if the seed save fails, the app still runs with an empty history.
            // Leave the flag unset so a later launch can retry.
        }
    }
}
