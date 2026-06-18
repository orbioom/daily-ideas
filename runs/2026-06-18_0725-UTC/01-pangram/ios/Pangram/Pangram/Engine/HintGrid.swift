import Foundation

/// Data for the "hints page": a two-way grid of word counts by first letter × length,
/// plus totals and the count of remaining (not-yet-found) words per first letter.
struct HintGrid {
    let letters: [Character]          // sorted distinct first letters present in solutions
    let lengths: [Int]                // sorted distinct word lengths present
    /// counts[letter][length] = number of solution words.
    let counts: [Character: [Int: Int]]
    /// remainingByLetter[letter] = solutions not yet found, by first letter.
    let remainingByLetter: [Character: Int]
    let totalWords: Int
    let totalRemaining: Int
    let pangramCount: Int
    let pangramsRemaining: Int

    func count(_ letter: Character, _ length: Int) -> Int {
        counts[letter]?[length] ?? 0
    }

    func rowTotal(_ letter: Character) -> Int {
        counts[letter]?.values.reduce(0, +) ?? 0
    }

    func columnTotal(_ length: Int) -> Int {
        letters.reduce(0) { $0 + count($1, length) }
    }
}

enum HintGridBuilder {
    static func build(puzzle: Puzzle, foundWords: Set<String>) -> HintGrid {
        var counts: [Character: [Int: Int]] = [:]
        var remaining: [Character: Int] = [:]
        var lengthSet = Set<Int>()
        var letterSet = Set<Character>()
        var totalRemaining = 0
        var pangramsRemaining = 0

        for word in puzzle.solutions {
            guard let first = word.first else { continue }
            let len = word.count
            letterSet.insert(first)
            lengthSet.insert(len)
            counts[first, default: [:]][len, default: 0] += 1
            if !foundWords.contains(word) {
                remaining[first, default: 0] += 1
                totalRemaining += 1
            }
        }

        for word in puzzle.pangrams where !foundWords.contains(word) {
            pangramsRemaining += 1
        }

        return HintGrid(
            letters: letterSet.sorted(),
            lengths: lengthSet.sorted(),
            counts: counts,
            remainingByLetter: remaining,
            totalWords: puzzle.solutions.count,
            totalRemaining: totalRemaining,
            pangramCount: puzzle.pangrams.count,
            pangramsRemaining: pangramsRemaining
        )
    }
}
