import Foundation
import SwiftData

/// Seeds a little realistic progress on first launch so the Levels map and
/// Word Jar aren't empty on a fresh install. Guarded to run only once.
enum SeedData {
    private static let seededKey = "didSeedV1"

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }

        // Mark first three Garden levels complete with a few stars.
        let completed: [(String, Int, Int)] = [
            ("garden-01", 3, 1),
            ("garden-02", 3, 3),
            ("garden-03", 2, 2)
        ]
        for (lvl, stars, bonus) in completed {
            let progress = LevelProgress(
                levelID: lvl,
                completed: true,
                starsEarned: stars,
                bonusFoundCount: bonus,
                completedAt: Date().addingTimeInterval(-Double.random(in: 3600...172_800))
            )
            context.insert(progress)
        }

        // A handful of bonus words already in the jar.
        let bonusSeeds: [(String, String)] = [
            ("DEE", "garden-01"),
            ("APT", "garden-02"),
            ("PAN", "garden-02"),
            ("TAN", "garden-02"),
            ("RES", "garden-03"),
            ("OES", "garden-03")
        ]
        for (word, lvl) in bonusSeeds {
            let bw = FoundBonusWord(
                word: word,
                firstFoundLevel: lvl,
                foundAt: Date().addingTimeInterval(-Double.random(in: 3600...172_800))
            )
            context.insert(bw)
        }

        do {
            try context.save()
            defaults.set(true, forKey: seededKey)
        } catch {
            // Non-fatal: if saving the seed fails the app still runs with empty data.
            // Leave the flag unset so a later launch can retry.
        }
    }
}
