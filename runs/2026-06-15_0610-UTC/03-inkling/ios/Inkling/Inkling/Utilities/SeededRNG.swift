import Foundation

/// A small, fast, fully deterministic PRNG (SplitMix64). Used so the seeded sample data and
/// any synthetic noise look identical on every launch — important for previews and demos.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A non-negative integer in `0..<upper` (upper must be > 0; falls back to 0 otherwise).
    mutating func int(_ upper: Int) -> Int {
        guard upper > 0 else { return 0 }
        return Int(next() % UInt64(upper))
    }

    /// A double in `0..<1`.
    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// A roughly-Gaussian sample (sum of uniforms), mean 0, in about ±3.
    mutating func gaussian() -> Double {
        (unit() + unit() + unit() + unit() + unit() + unit() - 3.0)
    }
}
