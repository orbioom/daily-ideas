import Foundation

/// "What should I spin?" — a seeded surprise pick from the owned collection.
/// Prefers less-recently-spun records for variety when `preferUnplayed` is on.
enum SpinPicker {

    /// Pick a record id from `records`, optionally filtered by genre/decade.
    /// Returns nil when nothing matches. Deterministic for a given `seed`.
    static func pick(from records: [Record],
                     genre: Genre? = nil,
                     decade: Int? = nil,
                     preferUnplayed: Bool,
                     seed: UInt64,
                     now: Date = .now) -> UUID? {
        let pool = records.filter { rec in
            guard rec.status == .owned else { return false }
            if let genre, rec.genre != genre { return false }
            if let decade, rec.decade != decade { return false }
            return true
        }
        guard !pool.isEmpty else { return nil }

        if preferUnplayed {
            // Weight toward records not spun recently. A record never spun gets the
            // largest weight; recently spun records get the smallest.
            let weighted = pool.map { rec -> (UUID, Double) in
                let weight: Double
                if let last = rec.lastSpinDate {
                    let days = max(0, now.timeIntervalSince(last) / 86_400)
                    // 1 day → ~1.0, 365 days → ~6.9; bounded and always positive.
                    weight = 1.0 + log(1.0 + days)
                } else {
                    weight = 12.0 // never spun → strong preference
                }
                return (rec.id, weight)
            }
            return weightedChoice(weighted, seed: seed)
        } else {
            var rng = SeededRNG(seed: seed)
            let idx = Int(rng.next() % UInt64(pool.count))
            return pool[safe: idx]?.id
        }
    }

    /// Deterministic weighted choice.
    private static func weightedChoice(_ items: [(UUID, Double)], seed: UInt64) -> UUID? {
        let total = items.reduce(0.0) { $0 + max(0, $1.1) }
        guard total > 0 else { return items.first?.0 }
        var rng = SeededRNG(seed: seed)
        // Random fraction in 0..<1.
        let r = Double(rng.next() % 1_000_000) / 1_000_000.0
        var threshold = r * total
        for (id, weight) in items {
            threshold -= max(0, weight)
            if threshold <= 0 { return id }
        }
        return items.last?.0
    }
}

/// A tiny deterministic SplitMix64 generator (no Foundation randomness).
struct SeededRNG {
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

extension Array {
    /// Safe indexing — nil instead of a crash on out-of-range.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
