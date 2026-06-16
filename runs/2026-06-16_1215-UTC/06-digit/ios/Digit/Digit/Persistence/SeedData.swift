import Foundation
import SwiftData

/// Seeds one realistic demo child on first launch so Progress & Rewards are populated.
@MainActor
enum SeedData {

    /// Guarded so it runs exactly once. Returns the profile to select, if any.
    @discardableResult
    static func seedIfNeeded(context: ModelContext) -> Profile? {
        // Guard: if any profile already exists, do nothing.
        let descriptor = FetchDescriptor<Profile>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if !existing.isEmpty { return existing.first }

        let profile = Profile(name: "Ava",
                              avatarEmoji: "🦊",
                              currentLevelIndex: 3,
                              maxNumber: 20,
                              enabledOps: [.add, .sub])
        context.insert(profile)

        // Use a deterministic generator so the seed is reproducible & realistic.
        var generator: RandomNumberGenerator = SeededGenerator(seed: 20_260_616)

        seedFacts(into: profile, context: context, rng: &generator)
        seedSessions(into: profile, context: context, rng: &generator)

        try? context.save()
        return profile
    }

    // MARK: - Facts

    private static func seedFacts(into profile: Profile,
                                  context: ModelContext,
                                  rng: inout RandomNumberGenerator) {
        // Build add (within 20) and sub (within 20) fact pools, then sample ~60.
        let addPool = FactEngine.allFacts(ops: [.add], maxNumber: 20)
        let subPool = FactEngine.allFacts(ops: [.sub], maxNumber: 20)

        let addSample = sample(addPool, count: 36, rng: &rng)
        let subSample = sample(subPool, count: 26, rng: &rng)
        let combined = addSample + subSample

        let now = Date.now
        for (i, fact) in combined.enumerated() {
            let stat = FactStat(op: fact.op, a: fact.a, b: fact.b)
            // Vary mastery across the realistic spread (more learning than mastered).
            let bucket = i % 10
            let mastery: Int
            switch bucket {
            case 0, 1, 2: mastery = 3
            case 3, 4, 5: mastery = 2
            case 6, 7: mastery = 1
            default: mastery = 0
            }
            stat.masteryLevel = mastery
            if mastery > 0 {
                let seen = Int.random(in: 2...12, using: &rng)
                stat.timesSeen = seen
                let accuracyBase = Double(mastery) / 3.0
                let correct = max(1, Int((Double(seen) * (0.55 + accuracyBase * 0.4)).rounded()))
                stat.timesCorrect = min(seen, correct)
                stat.fastestMs = Int.random(in: 1_400...(6_000 - mastery * 900), using: &rng)
                let daysAgo = Double(Int.random(in: 0...9, using: &rng))
                stat.lastSeen = now.addingTimeInterval(-daysAgo * 86_400)
            }
            stat.profile = profile
            context.insert(stat)
        }
    }

    // MARK: - Sessions

    private static func seedSessions(into profile: Profile,
                                     context: ModelContext,
                                     rng: inout RandomNumberGenerator) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // 12 sessions spread across the last ~14 days (a couple of days skipped).
        let dayOffsets = [13, 12, 10, 9, 8, 6, 5, 4, 3, 2, 1, 0]
        let ops: [String] = ["add", "sub", "add", "mixed", "sub", "add",
                             "mixed", "sub", "add", "mixed", "add", "sub"]

        for (i, offset) in dayOffsets.enumerated() {
            let base = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            // Add a plausible time-of-day.
            let date = base.addingTimeInterval(Double(Int.random(in: 8...19, using: &rng)) * 3_600)
            let total = [5, 10, 10, 15].randomElement(using: &rng) ?? 10
            // Accuracy trends upward over time (learning curve).
            let progressFactor = Double(i) / Double(max(1, dayOffsets.count - 1))
            let baseAcc = 0.55 + progressFactor * 0.4
            let acc = min(1.0, max(0.3, baseAcc + Double.random(in: -0.12...0.1, using: &rng)))
            let correct = max(0, min(total, Int((Double(total) * acc).rounded())))
            let duration = Double(total) * Double.random(in: 3.2...6.5, using: &rng)
            let stars = FactEngine.stars(correct: correct, total: total)
            let opRaw = ops.indices.contains(i) ? ops[i] : "add"
            let session = Session(date: date,
                                  opRaw: opRaw,
                                  levelIndex: 3,
                                  total: total,
                                  correct: correct,
                                  durationSec: duration,
                                  starsEarned: stars)
            session.profile = profile
            context.insert(session)
        }
    }

    // MARK: - Helpers

    private static func sample(_ pool: [(op: MathOp, a: Int, b: Int)],
                              count: Int,
                              rng: inout RandomNumberGenerator) -> [(op: MathOp, a: Int, b: Int)] {
        guard !pool.isEmpty else { return [] }
        let shuffled = pool.shuffled(using: &rng)
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }
}

/// A small deterministic PRNG (SplitMix64) for reproducible seeding.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
