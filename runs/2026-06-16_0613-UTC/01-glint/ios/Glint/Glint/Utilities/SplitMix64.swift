import Foundation

/// Deterministic, seedable RNG (SplitMix64). Injected into the engine so all
/// board generation, refills, and reshuffles are reproducible for a given seed.
struct SplitMix64: RandomNumberGenerator {
    private(set) var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    /// Restore from a previously captured `state` (for resuming saved games).
    init(rawState: UInt64) {
        self.state = rawState
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Returns an Int in 0..<upperBound (upperBound must be > 0; guarded by caller).
    mutating func int(below upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }
}

extension Date {
    /// A stable seed derived from the calendar day (UTC), for the Daily challenge.
    var daySeed: UInt64 {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let comps = cal.dateComponents([.year, .month, .day], from: self)
        let y = UInt64(comps.year ?? 2026)
        let m = UInt64(comps.month ?? 1)
        let d = UInt64(comps.day ?? 1)
        return (y &* 10_000) &+ (m &* 100) &+ d
    }

    /// "2026-06-16" formatted key for daily storage/lookup.
    var dayKey: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}
