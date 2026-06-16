import Foundation

/// A small, fast, deterministic pseudo-random number generator.
///
/// SplitMix64 is used so that a given seed (for example a date) always yields
/// the exact same sequence of values. This makes the "Daily" puzzle identical
/// for every player on a given day and makes puzzle generation reproducible.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state which would reduce randomness quality.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Returns an integer in `0..<upperBound`. Guards against a non-positive
    /// bound so callers never trigger a division/modulo trap on user paths.
    mutating func int(below upperBound: Int) -> Int {
        guard upperBound > 1 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    /// Fisher–Yates shuffle using this generator (deterministic for the seed).
    mutating func shuffled<T>(_ array: [T]) -> [T] {
        var result = array
        guard result.count > 1 else { return result }
        var i = result.count - 1
        while i > 0 {
            let j = int(below: i + 1)
            result.swapAt(i, j)
            i -= 1
        }
        return result
    }
}

extension SplitMix64 {
    /// Builds a stable seed from a "YYYY-MM-DD" date key string.
    static func seed(forDateKey key: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603 // FNV-1a offset basis
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}
