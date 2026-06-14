import Foundation

/// Deterministic SplitMix64 random number generator.
/// Used for the seeded piece bag; for the daily challenge it is seeded from
/// yyyyMMdd so everyone gets the same piece sequence on a given day.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Bounded non-negative integer in 0..<upper (upper must be > 0).
    mutating func int(_ upper: Int) -> Int {
        guard upper > 0 else { return 0 }
        return Int(next() % UInt64(upper))
    }
}

enum DailySeed {
    /// Stable seed for a date based on yyyyMMdd in the current calendar.
    static func seed(for date: Date, calendar: Calendar = .current) -> UInt64 {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = UInt64(comps.year ?? 2026)
        let m = UInt64(comps.month ?? 1)
        let d = UInt64(comps.day ?? 1)
        return y &* 10000 &+ m &* 100 &+ d
    }

    /// Stable string key "yyyyMMdd" for a date.
    static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d%02d%02d", y, m, d)
    }
}
