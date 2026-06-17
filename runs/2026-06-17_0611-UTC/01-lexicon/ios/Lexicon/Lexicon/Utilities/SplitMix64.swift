import Foundation

/// A small, fast, deterministic pseudo-random generator (SplitMix64).
/// Seeding with a fixed value (e.g. a date as yyyyMMdd) reproduces the exact same
/// stream — this powers Lexicon's deterministic daily puzzle selection so everyone
/// gets the same word on the same calendar day.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state producing a degenerate stream.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Helpers to turn a calendar date into a stable index into the answer list.
enum DailySeed {
    /// yyyyMMdd integer for a given date, in the user's current calendar.
    static func dateInt(for date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2026
        let m = c.month ?? 1
        let d = c.day ?? 1
        return y * 10_000 + m * 100 + d
    }

    /// A stable index into a list of `count` items for a given date.
    /// Same date + same list size always yields the same index.
    static func index(for date: Date, count: Int, calendar: Calendar = .current) -> Int {
        guard count > 0 else { return 0 }
        let seedInt = dateInt(for: date, calendar: calendar)
        var gen = SplitMix64(seed: UInt64(bitPattern: Int64(seedInt)))
        return Int(gen.next() % UInt64(count))
    }
}
