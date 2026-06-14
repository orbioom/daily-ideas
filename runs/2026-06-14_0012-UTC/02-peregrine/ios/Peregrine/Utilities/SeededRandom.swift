import Foundation

/// A small, deterministic pseudo-random generator (SplitMix64). Used for the
/// daily challenge so every learner gets the same set on a given date, and for
/// reproducible shuffles in tests/previews. Not for cryptographic use.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state which would weaken the first outputs.
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

extension String {
    /// A stable 64-bit hash (FNV-1a). `hashValue` is intentionally salted per
    /// run, so we use this when we need cross-launch determinism (daily seed).
    var stableSeed: UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in self.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
