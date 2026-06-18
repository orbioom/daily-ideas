import Foundation

/// Deterministic, seedable PRNG (SplitMix64). Used to make the Daily puzzle identical
/// for everyone on a given date, and to drive reproducible practice shuffles.
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

    /// Returns an index in `0..<count`, safe for empty ranges (returns 0).
    mutating func index(below count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(next() % UInt64(count))
    }
}

enum SeedKey {
    /// Hash an arbitrary string into a stable 64-bit seed (FNV-1a).
    static func hash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
