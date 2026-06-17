import Foundation

/// A deterministic, seedable pseudo-random generator (SplitMix64).
/// Given the same seed it always produces the same sequence — essential for
/// reproducing generative wallpapers from a stored spec.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state degenerate case while staying deterministic.
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A uniform Double in [0, 1).
    mutating func unit() -> Double {
        // Use the top 53 bits for full double precision in [0, 1).
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }

    /// A uniform Double in the given closed range.
    mutating func double(in range: ClosedRange<Double>) -> Double {
        let span = range.upperBound - range.lowerBound
        return range.lowerBound + unit() * span
    }

    /// A uniform Int in the given closed range.
    mutating func int(in range: ClosedRange<Int>) -> Int {
        guard range.upperBound > range.lowerBound else { return range.lowerBound }
        let span = UInt64(range.upperBound - range.lowerBound) + 1
        return range.lowerBound + Int(next() % span)
    }

    /// A small jittered offset in [-amount, amount].
    mutating func jitter(_ amount: Double) -> Double {
        double(in: -amount...amount)
    }
}
