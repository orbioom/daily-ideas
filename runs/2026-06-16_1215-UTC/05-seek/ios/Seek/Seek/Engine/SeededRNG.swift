import Foundation

/// Deterministic pseudo-random number generator (SplitMix64).
/// Identical seeds always yield identical sequences, so boards are reproducible.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state which would degrade the generator.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Returns an Int in 0..<upperBound. Returns 0 when upperBound <= 0 (guarded).
    mutating func int(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    /// Picks a uniformly random element, or nil for an empty collection.
    mutating func pick<T>(_ array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        return array[int(upperBound: array.count)]
    }

    /// Fisher–Yates shuffle that is fully reproducible from the seed.
    mutating func shuffled<T>(_ array: [T]) -> [T] {
        var copy = array
        guard copy.count > 1 else { return copy }
        var i = copy.count - 1
        while i > 0 {
            let j = int(upperBound: i + 1)
            copy.swapAt(i, j)
            i -= 1
        }
        return copy
    }
}
