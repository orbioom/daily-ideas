import Foundation
import SwiftData

/// Seeds realistic sample data so the Progress screen is rich on first launch.
enum SeedData {

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        insertSamples(context: context)
        didSeed = true
    }

    /// Seed regardless of the flag (used by the Settings "Load sample data" action).
    static func forceSeed(context: ModelContext) {
        insertSamples(context: context)
    }

    /// Wipe all sessions and note stats.
    static func clearAll(context: ModelContext) {
        if let sessions = try? context.fetch(FetchDescriptor<DrillSession>()) {
            for s in sessions { context.delete(s) }
        }
        if let stats = try? context.fetch(FetchDescriptor<NoteStat>()) {
            for s in stats { context.delete(s) }
        }
        try? context.save()
    }

    // MARK: - Generation

    private static func insertSamples(context: ModelContext) {
        var rng = SeededGenerator(seed: 20260601)
        let now = Date()
        let clefWeights: [(Clef, Int)] = [(.treble, 6), (.bass, 3), (.alto, 1)]

        // ~60 sessions across ~21 days; accuracy trends upward over time.
        let sessionCount = 60
        for i in 0..<sessionCount {
            // Older sessions first (i=0 is oldest).
            let dayOffset = Double(sessionCount - i) * (21.0 / Double(sessionCount))
            let jitter = Double(rng.next() % 6) * 600 // up to ~1hr scatter
            let date = now.addingTimeInterval(-(dayOffset * 86_400) - jitter)

            let clef = pickClef(clefWeights, &rng)
            let timed = (rng.next() % 5 == 0)
            let mode: DrillMode = timed ? .timed : .fixedCount
            let length = timed ? 0 : [10, 20, 50][Int(rng.next() % 3)]

            // Skill ramps from ~0.62 to ~0.95 across the run, plus noise.
            let progress = Double(i) / Double(max(1, sessionCount - 1))
            let baseAcc = 0.62 + 0.30 * progress
            let noise = (Double(rng.next() % 16) - 8) / 100.0
            let acc = min(0.99, max(0.4, baseAcc + noise))

            let total = timed ? Int(18 + rng.next() % 16) : length
            let correct = min(total, Int((Double(total) * acc).rounded()))
            let duration = timed ? 60 : Int(Double(total) * (1.6 + Double(rng.next() % 12) / 10.0))
            // Avg response time drops as skill grows: ~2.4s → ~1.0s.
            let avgMs = (2400 - 1400 * progress) + Double(Int(rng.next() % 400)) - 200
            let bestStreak = max(1, Int(Double(correct) * (0.4 + 0.4 * progress)))

            let session = DrillSession(date: date,
                                       clef: clef,
                                       mode: mode,
                                       total: total,
                                       correct: correct,
                                       durationSec: max(0, duration),
                                       avgMs: max(300, avgMs),
                                       bestStreak: bestStreak)
            context.insert(session)
        }

        // Note stats across the natural notes of treble, bass, and alto.
        for (clef, _) in clefWeights {
            let pool = MusicTheory.naturalMIDIs(in: NoteRange.oneLedger.midiRange(for: clef))
            for midi in pool {
                let seen = 8 + Int(rng.next() % 40)
                // Some notes mastered, some shaky — vary by pitch.
                let masteryBias = 0.55 + Double((midi % 7)) / 14.0
                let correct = min(seen, Int((Double(seen) * masteryBias).rounded()))
                let key = NoteStat.makeKey(clef: clef, midi: midi)
                let stat = NoteStat(key: key,
                                    seen: seen,
                                    correct: correct,
                                    lastSeen: now.addingTimeInterval(-Double(rng.next() % 200_000)))
                context.insert(stat)
            }
        }

        try? context.save()
    }

    private static func pickClef(_ weights: [(Clef, Int)], _ rng: inout SeededGenerator) -> Clef {
        let total = weights.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return .treble }
        let r = Int(rng.next() % UInt64(total))
        var acc = 0
        for (clef, w) in weights {
            acc += w
            if r < acc { return clef }
        }
        return .treble
    }
}

/// A tiny deterministic generator so seeded data is stable across launches.
private struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
