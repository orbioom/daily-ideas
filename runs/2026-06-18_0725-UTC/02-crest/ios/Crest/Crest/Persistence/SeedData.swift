import Foundation
import SwiftData

/// Seeds a realistic set of past results on first run so Stats / Daily streaks
/// are alive immediately. Guarded so it runs exactly once.
enum SeedData {
    private static let seededKey = "didSeedHistory_v1"

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: seededKey) { return }

        // Defensive: if data already exists, mark seeded and skip.
        let existing = (try? context.fetch(FetchDescriptor<GameResult>())) ?? []
        if !existing.isEmpty {
            defaults.set(true, forKey: seededKey)
            return
        }

        let results = buildSampleResults()
        for r in results { context.insert(r) }
        try? context.save()
        defaults.set(true, forKey: seededKey)
    }

    private static func buildSampleResults() -> [GameResult] {
        var rng = SplitMix64(seed: 0x5EED_1234_ABCD_5678)
        let calendar = Calendar.current
        let now = Date()
        var out: [GameResult] = []

        // ~32 games spread across the last ~45 days.
        let layouts: [BoardLayout] = [.threePeaks, .threePeaks, .threePeaks, .pyramid, .diamond]
        for i in 0..<32 {
            let daysAgo = Int(rng.next() % 45)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let layout = layouts[Int(rng.next() % UInt64(layouts.count))]
            let won = (rng.next() % 100) < 46            // ~46% win rate
            let cardsCleared = won ? 28 : Int(8 + rng.next() % 19)
            let combo = Int(2 + rng.next() % 12)
            let baseScore = cardsCleared * 50 + combo * 60
            let score = won ? baseScore + 500 + Int(rng.next() % 300)
                            : Int(Double(baseScore) * 0.7)
            let duration = Double(80 + rng.next() % 360)
            let isDaily = (rng.next() % 100) < 35
            let dealNumber = isDaily ? Format.dayKey(date) : Int(1000 + rng.next() % 9000)

            out.append(GameResult(
                layoutRaw: layout.rawValue,
                won: won,
                score: max(0, score),
                durationSec: duration,
                cardsCleared: cardsCleared,
                longestCombo: combo,
                dealNumber: dealNumber,
                isDaily: isDaily,
                date: date
            ))
        }

        // Guarantee a short recent daily win streak so the calendar looks alive.
        for back in 0..<4 {
            let date = calendar.date(byAdding: .day, value: -back, to: now) ?? now
            out.append(GameResult(
                layoutRaw: BoardLayout.threePeaks.rawValue,
                won: true,
                score: 1300 + back * 40,
                durationSec: Double(120 + back * 15),
                cardsCleared: 28,
                longestCombo: 9 + back,
                dealNumber: Format.dayKey(date),
                isDaily: true,
                date: date
            ))
        }
        return out
    }
}
