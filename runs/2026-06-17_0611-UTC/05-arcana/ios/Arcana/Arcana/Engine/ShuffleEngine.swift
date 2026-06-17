import Foundation

/// A small, fast, seedable PRNG (SplitMix64). Deterministic for a given seed — the basis
/// for the reproducible daily card and for optional user-seeded spreads.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A Double in 0..<1.
    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }
}

/// Pure tarot drawing. No I/O, no randomness beyond its seed — fully testable and deterministic.
enum ShuffleEngine {
    /// Draw `count` distinct cards from the full 78-card deck using the given generator,
    /// assigning each a reversed orientation with probability `reversalChance` (0...1).
    /// Returns `(cardId, reversed)` pairs. If `count` exceeds the deck, it's clamped.
    static func draw(count: Int,
                     reversalChance: Double,
                     using rng: inout SplitMix64) -> [(cardId: Int, reversed: Bool)] {
        let n = min(max(count, 0), Deck.all.count)
        guard n > 0 else { return [] }

        // Fisher–Yates partial shuffle over the card ids.
        var ids = Deck.all.map { $0.id }
        if ids.count > 1 {
            for i in 0..<(ids.count - 1) {
                let upper = ids.count - i
                let j = i + Int(rng.next() % UInt64(upper))
                ids.swapAt(i, j)
            }
        }

        let chosen = Array(ids.prefix(n))
        let p = min(max(reversalChance, 0), 1)
        return chosen.map { id in
            let reversed = rng.unit() < p
            return (cardId: id, reversed: reversed)
        }
    }

    /// The deterministic daily card for a given date. Same local day → same card + orientation,
    /// regardless of when in the day it's computed. Reversed only if reversals are allowed.
    static func dailyCard(for date: Date, reversalChance: Double) -> (cardId: Int, reversed: Bool) {
        var rng = SplitMix64(seed: seed(forDayKey: date.dayKey))
        let result = draw(count: 1, reversalChance: reversalChance, using: &rng)
        // Safe fallback to The Fool (id 0) if the deck were ever empty.
        return result.first ?? (cardId: 0, reversed: false)
    }

    /// Convenience: draw all positions for a spread with a fresh random seed.
    static func drawSpread(_ spread: SpreadType,
                           reversalChance: Double,
                           seed: UInt64? = nil) -> [(cardId: Int, reversed: Bool)] {
        var rng = SplitMix64(seed: seed ?? randomSeed())
        return draw(count: spread.cardCount, reversalChance: reversalChance, using: &rng)
    }

    /// A stable 64-bit seed derived from a "yyyy-MM-dd" day key via FNV-1a.
    static func seed(forDayKey key: String) -> UInt64 {
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001B3
        }
        return hash
    }

    /// A non-deterministic seed for fresh spread draws.
    static func randomSeed() -> UInt64 {
        UInt64(Date().timeIntervalSince1970 * 1000) ^ UInt64.random(in: 0...UInt64.max)
    }
}
