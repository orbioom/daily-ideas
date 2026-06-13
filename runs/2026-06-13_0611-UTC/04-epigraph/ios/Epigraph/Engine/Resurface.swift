import Foundation

/// Deterministic, seeded RNG for daily picks and review shuffles.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum Resurface {
    /// FNV-1a over the day string so the pick is stable for a whole calendar day.
    static func daySeed(_ date: Date) -> UInt64 {
        let key = Self.dayString(date)
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    static func dayString(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private static func ordered(_ highlights: [Highlight]) -> [Highlight] {
        highlights.sorted {
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.text < $1.text
        }
    }

    /// The deterministic highlight of the day.
    static func ofDay(_ highlights: [Highlight], date: Date = .now) -> Highlight? {
        let items = ordered(highlights)
        guard !items.isEmpty else { return nil }
        let idx = Int(daySeed(date) % UInt64(items.count))
        return items[idx]
    }

    /// A review batch that favours the least-recently-surfaced highlights,
    /// shuffled deterministically for the day so the set is stable until reviewed.
    static func batch(_ highlights: [Highlight], count: Int, date: Date = .now) -> [Highlight] {
        guard !highlights.isEmpty else { return [] }
        let byStaleness = highlights.sorted {
            if $0.lastSurfaced != $1.lastSurfaced { return $0.lastSurfaced < $1.lastSurfaced }
            return $0.surfaceCount < $1.surfaceCount
        }
        let pool = Array(byStaleness.prefix(max(count, count * 3)))
        var rng = SplitMix64(seed: daySeed(date) ^ 0xA5A5A5A5)
        return Array(pool.shuffled(using: &rng).prefix(count))
    }
}
