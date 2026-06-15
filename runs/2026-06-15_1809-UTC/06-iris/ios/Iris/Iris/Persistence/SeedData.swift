import Foundation
import SwiftData

/// Seeds ~8 weeks of realistic break + exercise history on first launch so Today and Insights
/// look alive immediately. Gated by a flag and by an empty store, preserving a true reset path.
enum SeedData {
    private static let seededKey = "didSeedActivity"

    static func seedIfNeeded(context: ModelContext) {
        if UserDefaults.standard.bool(forKey: seededKey) { return }

        // Don't seed over real user data.
        let breakCount = (try? context.fetch(FetchDescriptor<BreakLog>()))?.count ?? 0
        let sessionCount = (try? context.fetch(FetchDescriptor<ExerciseSession>()))?.count ?? 0
        guard breakCount == 0 && sessionCount == 0 else {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // A deterministic pseudo-random sequence so seeds are stable and believable.
        var rng = SeededGenerator(seed: 20_262_015)

        let routineNames = RoutineCatalog.routines.map(\.name)

        // Generate ~56 days of history. Recent ~10 days form a believable streak.
        for dayOffset in 1...56 {
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Probability of activity on a day: high recently, fading further back, with gaps.
            let recent = dayOffset <= 10
            let activeChance: Double = recent ? 0.96 : (dayOffset <= 28 ? 0.7 : 0.5)
            guard rng.unit() < activeChance else { continue }

            // Number of breaks that day: a believable spread.
            let base = recent ? 6 : 4
            let breaks = base + Int(rng.unit() * 5)   // base..base+4
            for _ in 0..<breaks {
                // Spread breaks across a workday window (9:00–18:00).
                let minute = 9 * 60 + Int(rng.unit() * 9 * 60)
                guard let stamp = cal.date(byAdding: .minute, value: minute, to: day) else { continue }
                let kind: BreakKind = rng.unit() < 0.85 ? .twentyRule : .longRest
                let dur = kind == .twentyRule ? 20 : (90 + Int(rng.unit() * 120))
                context.insert(BreakLog(date: stamp, kind: kind, durationSeconds: dur, completed: true))
            }

            // Some days also include an exercise routine.
            if rng.unit() < (recent ? 0.6 : 0.35), let name = routineNames.randomElementSeeded(&rng) {
                let routine = RoutineCatalog.routines.first { $0.name == name }
                let totalSecs = routine?.totalSeconds ?? 120
                let count = routine?.exercises.count ?? 4
                let minute = 12 * 60 + Int(rng.unit() * 6 * 60)
                if let stamp = cal.date(byAdding: .minute, value: minute, to: day) {
                    context.insert(ExerciseSession(date: stamp,
                                                  routineName: name,
                                                  durationSeconds: totalSecs,
                                                  exercisesCompleted: count))
                    // Mirror as an exercise break for the dashboard activity feed.
                    context.insert(BreakLog(date: stamp, kind: .exercise, durationSeconds: totalSecs, completed: true))
                }
            }
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// Clears all seeded/logged activity (used by Settings "reset history"). Keeps prefs.
    static func clearAll(context: ModelContext) {
        if let breaks = try? context.fetch(FetchDescriptor<BreakLog>()) {
            for b in breaks { context.delete(b) }
        }
        if let sessions = try? context.fetch(FetchDescriptor<ExerciseSession>()) {
            for s in sessions { context.delete(s) }
        }
        try? context.save()
        // Allow a future re-seed if desired by clearing the flag.
        UserDefaults.standard.set(false, forKey: seededKey)
    }
}

/// A tiny deterministic generator (SplitMix64) so seeded data is stable across runs.
struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A value in 0..<1.
    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}

private extension Array {
    /// Deterministic random element using a seeded generator (guarded against empty).
    func randomElementSeeded(_ rng: inout SeededGenerator) -> Element? {
        guard !isEmpty else { return nil }
        let i = Int(rng.unit() * Double(count))
        return self[Swift.min(i, count - 1)]
    }
}
