import Foundation
import SwiftData

/// Seeds the built-in sites and ~5 months of realistic entries on first launch.
/// Guarded so it runs exactly once: if any site already exists, it does nothing.
enum SeedData {
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let siteDescriptor = FetchDescriptor<MeasurementSite>()
        let existing = (try? context.fetch(siteDescriptor)) ?? []
        guard existing.isEmpty else { return }

        // 1. Built-in sites with a couple of sensible default goals.
        let goals: [String: Double] = [
            "waist": 82,   // cm target
            "weight": 78   // kg target
        ]
        for (index, spec) in SiteCatalog.builtIn.enumerated() {
            let site = MeasurementSite(
                key: spec.key,
                name: spec.name,
                unitKind: spec.kind,
                isBuiltIn: true,
                goalValue: goals[spec.key],
                sortOrder: index
            )
            context.insert(site)
        }

        // 2. Realistic 5-month cut/recomp trend, weekly entries.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weeks = 21 // ~5 months
        var rng = SeededGenerator(seed: 42)

        // Baseline canonical values and a per-week linear drift.
        // weight slowly down, waist down, biceps up — believable recomp.
        let plans: [(key: String, start: Double, perWeek: Double, jitter: Double)] = [
            ("weight",   88.0,  -0.42, 0.5),
            ("bodyfat",  22.0,  -0.32, 0.6),
            ("neck",     39.0,  -0.04, 0.2),
            ("shoulders",122.0,  0.05, 0.4),
            ("chest",    104.0, -0.10, 0.4),
            ("waist",    92.0,  -0.40, 0.4),
            ("hips",     101.0, -0.18, 0.4),
            ("bicepL",   34.5,   0.07, 0.2),
            ("bicepR",   35.0,   0.08, 0.2),
            ("thighL",   58.0,  -0.06, 0.3),
            ("thighR",   58.3,  -0.06, 0.3),
            ("calfL",    38.5,   0.01, 0.2),
            ("calfR",    38.6,   0.01, 0.2),
            ("forearm",  29.0,   0.03, 0.15)
        ]

        for w in stride(from: weeks, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -(w * 7), to: today) else { continue }
            let weekIndex = Double(weeks - w)
            for plan in plans {
                // Not every site is measured every single week for realism, but
                // weight/waist/bodyfat always are.
                let alwaysMeasured = ["weight", "waist", "bodyfat"].contains(plan.key)
                if !alwaysMeasured && rng.nextUnit() < 0.18 { continue }
                let trend = plan.start + plan.perWeek * weekIndex
                let noise = (rng.nextUnit() - 0.5) * 2 * plan.jitter
                let value = max(0.5, trend + noise)
                let entry = MeasurementEntry(
                    siteKey: plan.key,
                    valueCanonical: (value * 100).rounded() / 100,
                    date: date
                )
                context.insert(entry)
            }
        }

        try? context.save()
    }
}

/// Tiny deterministic PRNG so the seeded data is identical across launches.
private struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform Double in the half-open unit interval from 0 up to 1.
    mutating func nextUnit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
