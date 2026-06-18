import Foundation

/// Deterministic seeded RNG (SplitMix64). Conforms to `RandomNumberGenerator`
/// so it can drive `shuffled(using:)`. Same seed always yields the same deal.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum SeedFactory {
    /// Build a stable seed from a layout + deal-number pair so a given deal
    /// number always produces the same board for a given layout.
    static func seed(layout: BoardLayout, dealNumber: Int) -> UInt64 {
        let base: UInt64 = 0xC0FF_EE12_3456_789A
        let l = UInt64(layout.rawValue.hashValue & 0xFFFF)
        let d = UInt64(bitPattern: Int64(dealNumber))
        return base ^ (l &* 0x1000_0001) ^ (d &* 0x9E37_79B9)
    }

    /// Deal number for "today's" daily, derived from the day key.
    static func dailyDealNumber(for date: Date) -> Int {
        Format.dayKey(date)
    }
}
