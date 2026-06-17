import Foundation

/// A tiny deterministic PRNG (splitmix64) so puzzle layout and tie-breaks are
/// reproducible for a given seed. Pure — no system entropy.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state, which would weaken the generator.
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    /// Convenience seed from an arbitrary string (stable across launches).
    init(seedString: String) {
        var hash: UInt64 = 1469598103934665603 // FNV-1a offset basis
        for byte in seedString.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        self.init(seed: hash)
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
