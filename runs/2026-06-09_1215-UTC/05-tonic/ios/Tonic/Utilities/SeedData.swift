import Foundation
import SwiftData

/// Seeds built-in drills plus a little realistic history on first launch so the
/// Drills list, Progress charts, and mastery bars are never empty for a new user.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Drill>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let drills: [Drill] = [
            Drill(name: "Perfect Intervals",
                  type: .interval,
                  enabledKeys: [Interval.m2, .M2, .P4, .P5, .P8].map(\.rawValue),
                  direction: .ascending, rootMode: .fixedC,
                  isBuiltIn: true, sortIndex: 0),
            Drill(name: "All Intervals",
                  type: .interval,
                  enabledKeys: Interval.allCases.filter { $0 != .unison }.map(\.rawValue),
                  direction: .ascending, rootMode: .random,
                  isBuiltIn: true, sortIndex: 1),
            Drill(name: "Triads",
                  type: .chord,
                  enabledKeys: [ChordType.major, .minor, .diminished, .augmented].map(\.rawValue),
                  direction: .harmonic, rootMode: .random,
                  isBuiltIn: true, sortIndex: 2),
            Drill(name: "Seventh Chords",
                  type: .chord,
                  enabledKeys: [ChordType.major7, .dominant7, .minor7].map(\.rawValue),
                  direction: .harmonic, rootMode: .random,
                  isBuiltIn: true, sortIndex: 3),
            Drill(name: "Scales",
                  type: .scale,
                  enabledKeys: [ScaleType.major, .naturalMinor, .dorian, .mixolydian].map(\.rawValue),
                  direction: .ascending, rootMode: .fixedC,
                  isBuiltIn: true, sortIndex: 4)
        ]
        drills.forEach { context.insert($0) }

        // ~40 sessions across the last ~6 weeks with varied accuracy.
        let cal = Calendar.current
        let names: [(String, DrillType)] = [
            ("Perfect Intervals", .interval),
            ("All Intervals", .interval),
            ("Triads", .chord),
            ("Seventh Chords", .chord),
            ("Scales", .scale)
        ]
        var rng = SeededGenerator(seed: 0xC0FFEE)
        for daysAgo in stride(from: 41, through: 0, by: -1) {
            // Practice on most days, occasionally twice, sometimes skip.
            let roll = Double.random(in: 0...1, using: &rng)
            let runs = roll < 0.18 ? 0 : (roll < 0.8 ? 1 : 2)
            for _ in 0..<runs {
                guard let date = cal.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
                let (name, type) = names.randomElement(using: &rng) ?? names[0]
                let total = Int.random(in: 8...20, using: &rng)
                // Accuracy improves gently over time (older days a bit worse).
                let base = 0.55 + (Double(41 - daysAgo) / 41.0) * 0.3
                let jitter = Double.random(in: -0.12...0.12, using: &rng)
                let acc = min(0.98, max(0.4, base + jitter))
                let correct = Int((Double(total) * acc).rounded())
                let dur = total * Int.random(in: 5...9, using: &rng)
                let jittered = cal.date(byAdding: .hour, value: Int.random(in: 8...21, using: &rng), to: date) ?? date
                context.insert(DrillSession(date: jittered, drillName: name, drillType: type,
                                            total: total, correct: correct, durationSec: dur))
            }
        }

        // ~12 item stats with realistic attempts/correct so mastery bars look real.
        let seededStats: [(DrillType, String, Int, Int)] = [
            (.interval, Interval.P5.rawValue, 64, 60),
            (.interval, Interval.P4.rawValue, 58, 50),
            (.interval, Interval.M3.rawValue, 52, 41),
            (.interval, Interval.m3.rawValue, 49, 36),
            (.interval, Interval.TT.rawValue, 33, 18),
            (.interval, Interval.m6.rawValue, 28, 15),
            (.interval, Interval.M7.rawValue, 24, 11),
            (.chord, ChordType.major.rawValue, 47, 44),
            (.chord, ChordType.minor.rawValue, 45, 40),
            (.chord, ChordType.diminished.rawValue, 30, 19),
            (.chord, ChordType.augmented.rawValue, 26, 14),
            (.scale, ScaleType.major.rawValue, 31, 28),
            (.scale, ScaleType.dorian.rawValue, 22, 13)
        ]
        for (type, raw, attempts, correct) in seededStats {
            let daysBack = Int.random(in: 0...5, using: &rng)
            let seen = cal.date(byAdding: .day, value: -daysBack, to: .now) ?? .now
            context.insert(ItemStat(key: ItemStat.key(type: type, itemRaw: raw),
                                    attempts: attempts, correct: correct, lastSeen: seen))
        }

        try? context.save()
    }
}

/// A tiny deterministic RNG so seeded history is varied yet reproducible.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
