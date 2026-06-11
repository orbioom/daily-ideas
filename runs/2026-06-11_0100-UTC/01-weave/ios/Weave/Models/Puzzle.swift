import SwiftUI

struct PuzzleGroup: Identifiable, Equatable {
    let id: Int
    let category: String
    let difficulty: Int   // 1 = yellow, 2 = green, 3 = blue, 4 = purple
    let words: [String]   // always 4

    static func == (lhs: PuzzleGroup, rhs: PuzzleGroup) -> Bool {
        lhs.id == rhs.id
    }
}

struct Puzzle: Identifiable {
    let id: Int
    let groups: [PuzzleGroup]  // always 4 groups → 16 words total

    var allWords: [String] { groups.flatMap(\.words) }

    // Deterministic shuffle seeded by puzzle id
    var shuffledWords: [String] {
        var words = allWords
        var rng = SeededRNG(seed: UInt64(id) &* 6364136223846793005 &+ 1442695040888963407)
        for i in stride(from: words.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            words.swapAt(i, j)
        }
        return words
    }
}

// Minimal seeded PRNG (LCG) for deterministic word shuffling
struct SeededRNG {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state >> 33
    }
}
