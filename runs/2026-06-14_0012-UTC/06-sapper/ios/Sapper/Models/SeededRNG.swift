import Foundation

/// Deterministic, seedable PRNG (SplitMix64). Used so the daily challenge board
/// is identical for everyone given the same seed, and so no-guess generation is
/// reproducible.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum SeedFactory {
    /// Build a stable seed from a "yyyy-MM-dd" key (used by the daily challenge).
    static func seed(forDateKey key: String) -> UInt64 {
        // FNV-1a 64-bit hash so the same string always maps to the same seed,
        // independent of Swift's per-process Hasher randomization.
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001B3
        }
        return hash
    }
}
