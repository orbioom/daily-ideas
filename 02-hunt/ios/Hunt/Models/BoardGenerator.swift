import Foundation

struct BoardGenerator {
    private static let weights: [(Character, Int)] = [
        ("E", 13), ("T", 9), ("A", 8), ("O", 8), ("I", 7), ("N", 7),
        ("S", 6),  ("H", 6), ("R", 6), ("D", 4), ("L", 4), ("C", 3),
        ("U", 3),  ("M", 2), ("W", 2), ("F", 2), ("G", 2), ("Y", 2),
        ("P", 2),  ("B", 2), ("V", 1), ("K", 1), ("J", 1), ("X", 1),
        ("Q", 1),  ("Z", 1)
    ]

    static func generate(seed: UInt64? = nil) -> [[Character]] {
        var rng = SplitMix64(seed: seed ?? UInt64(abs(Date().timeIntervalSince1970 * 1000)))
        var pool: [Character] = []
        for (ch, w) in weights {
            for _ in 0..<w { pool.append(ch) }
        }
        var result: [[Character]] = []
        for _ in 0..<4 {
            var row: [Character] = []
            for _ in 0..<4 {
                let idx = Int(rng.next() % UInt64(pool.count))
                row.append(pool[idx])
            }
            result.append(row)
        }
        return result
    }

    static func dailySeed(for date: Date = .now) -> UInt64 {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = UInt64(comps.year ?? 2024)
        let m = UInt64(comps.month ?? 1)
        let d = UInt64(comps.day ?? 1)
        return y * 10000 + m * 100 + d
    }
}

struct SplitMix64 {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
