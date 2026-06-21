import Foundation

struct SlidePuzzle {
    let size: Int
    var tiles: [Int]  // 0 = blank, 1..(size²-1) = numbered tiles
    var moves: Int = 0
    var startTime: Date = Date()

    var blankIndex: Int { tiles.firstIndex(of: 0) ?? 0 }

    var isSolved: Bool {
        for i in 0..<(tiles.count - 1) {
            if tiles[i] != i + 1 { return false }
        }
        return tiles[tiles.count - 1] == 0
    }

    func adjacentToBlank(_ index: Int) -> Bool {
        let blank = blankIndex
        let row = index / size
        let col = index % size
        let br = blank / size
        let bc = blank % size
        return (row == br && abs(col - bc) == 1) || (col == bc && abs(row - br) == 1)
    }

    mutating func slide(at index: Int) -> Bool {
        guard adjacentToBlank(index) else { return false }
        let blank = blankIndex
        tiles.swapAt(index, blank)
        moves += 1
        return true
    }

    var elapsedSeconds: Double { Date().timeIntervalSince(startTime) }

    static func isSolvable(tiles: [Int], size: Int) -> Bool {
        let noBlank = tiles.filter { $0 != 0 }
        var inversions = 0
        for i in 0..<noBlank.count {
            for j in (i + 1)..<noBlank.count {
                if noBlank[i] > noBlank[j] { inversions += 1 }
            }
        }
        if size % 2 == 1 { return inversions % 2 == 0 }
        let blankIdx = tiles.firstIndex(of: 0) ?? 0
        let blankRowFromBottom = size - 1 - (blankIdx / size)
        return (inversions + blankRowFromBottom) % 2 == 1
    }

    static func make(size: Int, seed: UInt64? = nil) -> SlidePuzzle {
        var tiles = Array(1..<(size * size)) + [0]
        var rng = seed.map { SplitMix64($0) } ?? SplitMix64(UInt64(Date().timeIntervalSince1970 * 1000))
        // Shuffle until solvable (retry loop, max 100 attempts)
        for _ in 0..<100 {
            tiles.shuffleInPlace(using: &rng)
            if isSolvable(tiles: tiles, size: size) { break }
        }
        return SlidePuzzle(size: size, tiles: tiles)
    }
}

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(_ seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

extension Array {
    mutating func shuffleInPlace(using rng: inout SplitMix64) {
        for i in stride(from: count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            swapAt(i, j)
        }
    }
}
