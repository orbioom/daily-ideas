import Foundation
import SwiftData

/// Seeds realistic first-run data once: level progress (first several cleared with
/// stars), ~30 past game records across modes, a couple of daily results, and a
/// Zen high score. Guarded by a flag so it runs exactly once.
enum SeedData {
    private static let seededKey = "didSeedData_v1"

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: seededKey) { return }

        seedLevelProgress(context)
        seedRecords(context)
        seedDailies(context)
        seedZen(context)

        do {
            try context.save()
            defaults.set(true, forKey: seededKey)
        } catch {
            // If saving fails we simply don't mark as seeded; app still runs empty-safe.
        }
    }

    @MainActor
    private static func seedLevelProgress(_ context: ModelContext) {
        var rng = SplitMix64(seed: 424242)
        for level in LevelCatalog.all {
            let unlocked = level.id <= 6        // first cleared run unlocks up to 6
            let completed = level.id <= 5
            var stars = 0
            var best = 0
            if completed {
                stars = max(1, level.starThresholds.count - (level.id % 3))
                best = level.starThresholds[max(0, min(level.starThresholds.count - 1, stars - 1))] + rng.int(below: 400)
            }
            let progress = LevelProgress(
                levelID: level.id,
                stars: stars,
                bestScore: best,
                unlocked: unlocked || level.id == 1,
                completed: completed
            )
            context.insert(progress)
        }
    }

    @MainActor
    private static func seedRecords(_ context: ModelContext) {
        var rng = SplitMix64(seed: 991133)
        let now = Date()
        let modes: [GameMode] = [.level, .zen, .daily]
        for i in 0..<32 {
            let daysAgo = Double(i) * 0.8 + Double(rng.int(below: 12)) * 0.1
            let date = now.addingTimeInterval(-daysAgo * 86_400)
            let mode = modes[rng.int(below: modes.count)]
            let score = 600 + rng.int(below: 4200)
            let stars = mode == .level ? 1 + rng.int(below: 3) : 0
            let combo = 1 + rng.int(below: 6)
            let cleared = 30 + rng.int(below: 180)
            let levelID = mode == .level ? 1 + rng.int(below: 8) : nil
            let rec = GameRecord(
                date: date,
                modeRaw: mode.rawValue,
                score: score,
                levelID: levelID,
                stars: stars,
                bestCombo: combo,
                gemsCleared: cleared
            )
            context.insert(rec)
        }
    }

    @MainActor
    private static func seedDailies(_ context: ModelContext) {
        var rng = SplitMix64(seed: 770022)
        let cal = Calendar(identifier: .gregorian)
        for i in 1...6 {
            guard let date = cal.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let won = rng.int(below: 10) > 3
            let result = DailyResult(
                dayKey: date.dayKey,
                date: date,
                score: 1200 + rng.int(below: 3000),
                moves: 18 + rng.int(below: 8),
                won: won
            )
            context.insert(result)
        }
    }

    @MainActor
    private static func seedZen(_ context: ModelContext) {
        context.insert(ZenScore(key: "zen", highScore: 8_640))
    }
}
