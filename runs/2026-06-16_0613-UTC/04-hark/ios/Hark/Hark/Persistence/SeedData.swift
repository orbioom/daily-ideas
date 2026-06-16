import Foundation
import SwiftData

/// Seeds a few realistic past tests + a tinnitus match so History/trend demo well.
/// Guarded by a UserDefaults flag so it runs exactly once.
enum SeedData {
    private static let seededKey = "didSeedV1"

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }

        // Only seed if truly empty (defensive against double-seeding).
        let existing = (try? context.fetch(FetchDescriptor<HearingTest>())) ?? []
        guard existing.isEmpty else {
            defaults.set(true, forKey: seededKey)
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // Four past tests, oldest first, with a gentle high-frequency drift on the left ear
        // so the trend chart shows a story.
        let plans: [(daysAgo: Int, left: [Int: Double], right: [Int: Double])] = [
            (120,
             [250: 10, 500: 10, 1000: 15, 2000: 20, 4000: 25, 8000: 30],
             [250: 5, 500: 10, 1000: 10, 2000: 15, 4000: 20, 8000: 25]),
            (84,
             [250: 10, 500: 15, 1000: 15, 2000: 25, 4000: 30, 8000: 40],
             [250: 10, 500: 10, 1000: 15, 2000: 15, 4000: 20, 8000: 30]),
            (45,
             [250: 10, 500: 15, 1000: 20, 2000: 25, 4000: 35, 8000: 45],
             [250: 5, 500: 10, 1000: 15, 2000: 20, 4000: 25, 8000: 30]),
            (12,
             [250: 15, 500: 15, 1000: 20, 2000: 30, 4000: 40, 8000: 50],
             [250: 10, 500: 10, 1000: 15, 2000: 20, 4000: 25, 8000: 35])
        ]

        for plan in plans {
            let date = calendar.date(byAdding: .day, value: -plan.daysAgo, to: now) ?? now
            let test = HearingTest(date: date, maxLevelUsed: 80)
            test.ptaLeft = Audiometry.pta(from: plan.left)
            test.ptaRight = Audiometry.pta(from: plan.right)
            context.insert(test)

            for (freq, db) in plan.left {
                context.insert(Threshold(ear: .left, frequency: freq, dbLevel: db, test: test))
            }
            for (freq, db) in plan.right {
                context.insert(Threshold(ear: .right, frequency: freq, dbLevel: db, test: test))
            }
        }

        // A saved tinnitus match.
        let matchDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        context.insert(TinnitusMatch(date: matchDate, frequency: 6300, ear: .left,
                                     note: "High thin whistle, worse in quiet rooms."))

        do {
            try context.save()
            defaults.set(true, forKey: seededKey)
        } catch {
            // If saving fails we simply don't mark as seeded; app still works with no data.
        }
    }
}
