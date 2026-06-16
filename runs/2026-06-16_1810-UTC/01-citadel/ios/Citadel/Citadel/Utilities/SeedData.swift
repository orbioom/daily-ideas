import Foundation
import SwiftData

/// Seeds realistic past results on first run so the Stats screen looks alive.
enum SeedData {

    /// Insert ~30 plausible GameResult records spread over recent weeks.
    /// Idempotent-ish: only call when the store has no results.
    @MainActor
    static func seedResultsIfNeeded(context: ModelContext) {
        // Check current count; only seed an empty store.
        let descriptor = FetchDescriptor<GameResult>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let calendar = Calendar.current
        let now = Date()

        // A deterministic-ish sequence with realistic win/loss mix (FreeCell is ~99% winnable,
        // but human players lose plenty), durations, and move counts.
        // wins:true/false pattern over 30 games, ordered oldest -> newest.
        let pattern: [Bool] = [
            true, true, false, true, true, true, false, true, true, true,   // early run
            false, true, true, false, true, true, true, true, false, true,  // middle
            true, true, false, true, true, true, true, false, true, true    // recent, strong streak
        ]

        for (i, won) in pattern.enumerated() {
            // Spread across the last ~8 weeks, a few games per week.
            let daysAgo = (pattern.count - i) * 2 + Int.random(in: 0...1)
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

            let dealNumber = Int.random(in: 1...64000)
            let duration: Int = won
                ? Int.random(in: 95...420)     // 1.5–7 minutes for wins
                : Int.random(in: 60...300)     // gave up earlier on losses
            let moves: Int = won
                ? Int.random(in: 90...180)
                : Int.random(in: 20...110)

            let result = GameResult(
                dealNumber: dealNumber,
                won: won,
                durationSeconds: duration,
                moves: moves,
                date: date
            )
            context.insert(result)
        }

        try? context.save()
    }
}
