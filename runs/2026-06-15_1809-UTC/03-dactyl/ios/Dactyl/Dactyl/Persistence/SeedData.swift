import Foundation
import SwiftData

/// Seeds a realistic 8-week practice history on first launch so Stats and the key heatmap are
/// rich immediately. Gated by a flag and an emptiness check so a returning user is never
/// re-seeded, and a genuinely cleared store stays empty.
enum SeedData {
    private static let seededKey = "didSeedDactyl"

    static func seedIfNeeded(context: ModelContext) {
        if UserDefaults.standard.bool(forKey: seededKey) { return }

        let resultDescriptor = FetchDescriptor<TestResult>()
        let existing = (try? context.fetch(resultDescriptor)) ?? []
        guard existing.isEmpty else {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        seedResults(context: context)
        seedProgress(context: context)
        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    private static func seedResults(context: ModelContext) {
        var rng = SeededGenerator(seed: 0xDAC7_1ABE)
        let calendar = Calendar.current
        let now = Date()

        // Keys that a learner commonly fumbles, weighted so the heatmap has clear hot spots.
        let troubleKeys: [(String, Int)] = [
            ("p", 6), ("q", 5), ("z", 5), ("x", 4), (";", 4),
            ("b", 3), ("y", 3), ("m", 3), ("w", 2), ("v", 2),
            ("o", 2), ("u", 2), (",", 2), (".", 2)
        ]

        let titles = ["Home Row", "Common Words", "Sentences", "30s Test", "Top Row", "60s Test"]

        // 56 sessions across 8 weeks (one per day), WPM trending up from ~28 to ~62.
        let totalSessions = 56
        for i in 0..<totalSessions {
            let daysAgo = totalSessions - 1 - i
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }

            let progressFraction = Double(i) / Double(max(1, totalSessions - 1))
            // Rising trend with some jitter.
            let jitter = Double(rng.next() % 7) - 3.0          // -3...+3
            let baseWPM = 28.0 + progressFraction * 34.0 + jitter
            let wpm = max(18.0, baseWPM)

            // Accuracy improves with practice (0.90 -> 0.985) with mild jitter.
            let accJitter = (Double(rng.next() % 30) - 15.0) / 1000.0
            let accuracy = min(0.995, max(0.86, 0.90 + progressFraction * 0.085 + accJitter))

            let durationSeconds: Double = [15.0, 30.0, 60.0][Int(rng.next() % 3)]
            // Chars typed scales with wpm & duration.
            let charCount = max(20, Int(wpm * 5.0 * (durationSeconds / 60.0)))
            let errorCount = max(0, Int(Double(charCount) * (1.0 - accuracy)))

            // Distribute errors across trouble keys (fewer errors as the learner improves).
            var keyErrors: [String: Int] = [:]
            var remaining = errorCount
            for (key, weight) in troubleKeys {
                guard remaining > 0 else { break }
                // Earlier sessions concentrate errors on hard keys more heavily.
                let take = Int((Double(weight) * (1.0 - progressFraction * 0.5)).rounded())
                let amount = min(remaining, max(0, take == 0 && remaining > 0 && (rng.next() % 3 == 0) ? 1 : take))
                if amount > 0 {
                    keyErrors[key, default: 0] += amount
                    remaining -= amount
                }
            }
            // Any leftover errors land on a random letter.
            if remaining > 0 {
                let pool = KeyHeatmap.letterKeys
                let k = pool[Int(rng.next() % UInt64(pool.count))]
                keyErrors[k, default: 0] += remaining
            }

            let modePick = Int(rng.next() % 3)
            let mode: SessionMode = modePick == 0 ? .lesson : (modePick == 1 ? .test : .drill)
            let title = titles[Int(rng.next() % UInt64(titles.count))]

            let result = TestResult(
                date: date,
                mode: mode,
                referenceTitle: title,
                wpm: (wpm * 10).rounded() / 10,
                accuracy: accuracy,
                durationSeconds: durationSeconds,
                charCount: charCount,
                errorCount: errorCount,
                keyErrors: keyErrors
            )
            context.insert(result)
        }
    }

    private static func seedProgress(context: ModelContext) {
        // Mark the free Home Row lessons as practiced with believable bests.
        let seeds: [(id: String, wpm: Double, acc: Double, done: Bool, attempts: Int)] = [
            ("home-row", 58.0, 0.97, true, 9),
            ("home-row-words", 51.0, 0.95, true, 6)
        ]
        let calendar = Calendar.current
        for s in seeds {
            let progress = LessonProgress(
                lessonID: s.id,
                bestWPM: s.wpm,
                bestAccuracy: s.acc,
                completed: s.done,
                attempts: s.attempts,
                lastPracticed: calendar.date(byAdding: .day, value: -2, to: Date())
            )
            context.insert(progress)
        }
    }
}
