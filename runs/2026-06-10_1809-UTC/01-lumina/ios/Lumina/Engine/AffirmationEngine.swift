import Foundation

/// Deterministic selection helpers. The "affirmation of the day" is stable for
/// a given calendar day (and set of enabled themes) so the home screen does not
/// shuffle on every appearance, yet differs day to day.
enum AffirmationEngine {

    /// FNV-1a 64-bit hash of a string — a tiny, dependency-free, stable hash.
    static func fnv1a(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    static func dayKey(_ date: Date = .now) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Pick a stable index into `count` items for the given day.
    static func dailyIndex(count: Int, date: Date = .now, salt: String = "") -> Int {
        guard count > 0 else { return 0 }
        let h = fnv1a(dayKey(date) + "|" + salt)
        return Int(h % UInt64(count))
    }

    /// Deterministic affirmation of the day from a candidate pool.
    static func dailyAffirmation(from pool: [Affirmation], date: Date = .now) -> Affirmation? {
        guard !pool.isEmpty else { return nil }
        let sorted = pool.sorted { $0.id.uuidString < $1.id.uuidString }
        return sorted[dailyIndex(count: sorted.count, date: date)]
    }

    /// A deterministic ordering for the day's deck so swiping is repeatable
    /// within the day but varies between days. Uses a seeded shuffle.
    static func deck(from pool: [Affirmation], date: Date = .now) -> [Affirmation] {
        guard pool.count > 1 else { return pool }
        var items = pool.sorted { $0.id.uuidString < $1.id.uuidString }
        var seed = fnv1a(dayKey(date) + "|deck")
        // Fisher–Yates with a SplitMix64 generator seeded from the day.
        func next() -> UInt64 {
            seed = seed &+ 0x9E3779B97F4A7C15
            var z = seed
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
        var i = items.count - 1
        while i > 0 {
            let j = Int(next() % UInt64(i + 1))
            items.swapAt(i, j)
            i -= 1
        }
        return items
    }
}
