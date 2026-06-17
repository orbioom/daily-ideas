import Foundation
import SwiftData

/// Seeds realistic learner progress on first launch (idempotent via a count check).
enum SeedData {

    static func seedIfNeeded(context: ModelContext) {
        // Idempotent: only seed when there are no ItemStats yet.
        let descriptor = FetchDescriptor<ItemStat>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        seed(context: context)
    }

    /// Force a reseed (used by "Load sample data" in Settings).
    static func loadSample(context: ModelContext) {
        clearAll(context: context)
        seed(context: context)
    }

    static func clearAll(context: ModelContext) {
        if let stats = try? context.fetch(FetchDescriptor<ItemStat>()) {
            for s in stats { context.delete(s) }
        }
        if let sessions = try? context.fetch(FetchDescriptor<DrillSession>()) {
            for s in sessions { context.delete(s) }
        }
        try? context.save()
    }

    // MARK: - Seeding

    private static func seed(context: ModelContext) {
        var rng = SeededGenerator(seed: 42)

        // Spanish core tenses across many verbs, with varied mastery.
        let coreTenses = Tense.freeSpanishTenses
        let spanishVerbs = VerbCatalog.spanish.prefix(30)
        for (vi, verb) in spanishVerbs.enumerated() {
            for tense in coreTenses {
                // Skip a few to leave gaps (realistic).
                if (vi + tense.rawValue.count) % 7 == 0 { continue }
                let attempts = Int.random(in: 2...14, using: &rng)
                // Bias mastery: earlier verbs (common/irregular) trend higher.
                let base = Double.random(in: 0.15...0.95, using: &rng)
                let mastery = min(0.99, max(0.05, base))
                let correct = Int((Double(attempts) * (0.4 + mastery * 0.55)).rounded())
                let stat = ItemStat(verbInfinitive: verb.infinitive,
                                    language: Language.spanish.rawValue,
                                    tense: tense.rawValue,
                                    correct: min(correct, attempts),
                                    attempts: attempts,
                                    lastSeen: Date().addingTimeInterval(-Double(vi) * 3600),
                                    mastery: mastery)
                context.insert(stat)
            }
        }

        // A little French progress too (présent / imparfait) for Pro demos.
        let frenchVerbs = VerbCatalog.french.prefix(10)
        for (vi, verb) in frenchVerbs.enumerated() {
            for tense in [Tense.present, .imparfait] {
                if vi % 3 == 0 { continue }
                let attempts = Int.random(in: 1...8, using: &rng)
                let mastery = Double.random(in: 0.1...0.8, using: &rng)
                let correct = Int((Double(attempts) * (0.4 + mastery * 0.5)).rounded())
                let stat = ItemStat(verbInfinitive: verb.infinitive,
                                    language: Language.french.rawValue,
                                    tense: tense.rawValue,
                                    correct: min(correct, attempts),
                                    attempts: attempts,
                                    lastSeen: Date().addingTimeInterval(-Double(vi) * 7200),
                                    mastery: mastery)
                context.insert(stat)
            }
        }

        // ~15 past Spanish sessions over recent days for the accuracy line + streak.
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        // Days offsets chosen so the most recent run is yesterday/today → live streak.
        let dayOffsets = [0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 14, 16, 18, 21]
        for (i, offset) in dayOffsets.enumerated() {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let total = [8, 10, 12, 15].randomElement(using: &rng) ?? 10
            // Accuracy improves over time (older = lower).
            let improvement = Double(dayOffsets.count - i) / Double(dayOffsets.count)
            let acc = min(0.98, 0.5 + improvement * 0.45 + Double.random(in: -0.08...0.08, using: &rng))
            let correct = max(0, min(total, Int((Double(total) * acc).rounded())))
            let session = DrillSession(date: day.addingTimeInterval(Double.random(in: 0...50000, using: &rng)),
                                       language: Language.spanish.rawValue,
                                       mode: AnswerMode.type.rawValue,
                                       total: total,
                                       correct: correct,
                                       durationSeconds: total * Int.random(in: 6...12, using: &rng))
            context.insert(session)
        }

        try? context.save()
    }
}

/// Deterministic RNG for reproducible seed data.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
