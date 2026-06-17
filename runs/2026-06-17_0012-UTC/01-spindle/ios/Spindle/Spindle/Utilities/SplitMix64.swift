import Foundation

/// A small, fast, deterministic pseudo-random generator (SplitMix64).
/// Seeding with a fixed value (e.g. a date as yyyyMMdd) reproduces the exact
/// same shuffle — this powers Spindle's Daily Deal and numbered deals.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state producing a degenerate stream.
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

extension Array {
    /// Deterministic Fisher–Yates shuffle driven by a provided generator.
    func deterministicShuffled<G: RandomNumberGenerator>(using generator: inout G) -> [Element] {
        var copy = self
        guard copy.count > 1 else { return copy }
        for i in stride(from: copy.count - 1, to: 0, by: -1) {
            let j = Int(generator.next() % UInt64(i + 1))
            copy.swapAt(i, j)
        }
        return copy
    }
}

/// Helpers to turn dates / deal numbers into stable seeds.
enum DealSeed {
    /// yyyyMMdd integer for a given date, in the user's current calendar.
    static func dailySeedInt(for date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2026
        let m = c.month ?? 1
        let d = c.day ?? 1
        return y * 10_000 + m * 100 + d
    }

    /// A numbered deal seed is just the deal number salted into a wide space.
    static func numberedSeed(_ dealNumber: Int) -> UInt64 {
        let n = UInt64(bitPattern: Int64(dealNumber))
        return n &* 0x2545F4914F6CDD1D &+ 0xABCD_1234_5678_9EF0
    }
}
