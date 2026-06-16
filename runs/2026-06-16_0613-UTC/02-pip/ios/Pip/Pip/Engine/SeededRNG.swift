import Foundation

/// Deterministic, seedable PRNG (SplitMix64). Injected into the game engine so that
/// rolls are reproducible for the Daily challenge and for CPU determinism/tests.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state producing a degenerate stream.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Roll a single six-sided die (1...6).
    mutating func rollDie() -> Int {
        Int(next() % 6) + 1
    }
}

enum DailySeed {
    /// Stable seed for a given calendar day so every player sees the same dice stream.
    static func seed(for date: Date, calendar: Calendar = .current) -> UInt64 {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = UInt64(comps.year ?? 2026)
        let m = UInt64(comps.month ?? 1)
        let d = UInt64(comps.day ?? 1)
        return (y &* 10_000) &+ (m &* 100) &+ d &+ 0xD1CE
    }

    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 2026, comps.month ?? 1, comps.day ?? 1)
    }
}
