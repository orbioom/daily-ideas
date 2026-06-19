import Foundation

struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }

    mutating func nextInt(in range: Range<Int>) -> Int {
        let r = UInt64(range.count)
        guard r > 0 else { return range.lowerBound }
        return range.lowerBound + Int(next() % r)
    }
}
