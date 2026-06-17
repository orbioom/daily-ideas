import Foundation

/// A count-aware bag of letters. Pure value type used to verify that a
/// candidate word can be spelled from a set of available base letters,
/// using each letter at most as many times as it appears.
struct LetterMultiset: Equatable {
    private(set) var counts: [Character: Int]

    init(_ string: String) {
        var c: [Character: Int] = [:]
        for ch in string.uppercased() where ch.isLetter {
            c[ch, default: 0] += 1
        }
        counts = c
    }

    /// Total number of letters in the bag.
    var total: Int { counts.values.reduce(0, +) }

    /// True when `word` can be formed from this bag (count-aware, case-insensitive).
    func canForm(_ word: String) -> Bool {
        let needed = LetterMultiset(word)
        guard needed.total > 0 else { return false }
        for (ch, n) in needed.counts {
            if (counts[ch] ?? 0) < n { return false }
        }
        return true
    }

    /// The unique letters available, sorted for stable presentation.
    var uniqueLetters: [Character] {
        counts.keys.sorted()
    }

    /// The full list of available letters (with repeats), sorted for determinism.
    var allLetters: [Character] {
        var result: [Character] = []
        for ch in counts.keys.sorted() {
            for _ in 0..<(counts[ch] ?? 0) { result.append(ch) }
        }
        return result
    }
}
