import Foundation

/// A small, deterministic, seedable PRNG (SplitMix64). Used so the Daily
/// Challenge produces the same board for everyone on a given date, and so that
/// solvable-deal generation is reproducible/testable.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

extension UInt64 {
    /// Derive a stable seed from an arbitrary string (e.g. a date key + layout).
    init(stableSeed string: String) {
        // FNV-1a 64-bit.
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001B3
        }
        self = hash
    }
}
