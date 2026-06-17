import Foundation

/// Pure, deterministic evaluation of a guess against an answer of equal length.
///
/// Uses the correct TWO-PASS algorithm so duplicate letters are scored exactly like
/// the classic word game:
///   1. First pass marks exact-position matches as `.correct` and decrements a
///      per-letter remaining-count multiset built from the answer.
///   2. Second pass walks the non-green positions left-to-right and marks a letter
///      `.present` only while the remaining count for that letter is still positive,
///      decrementing as it goes. Anything else is `.absent`.
enum GuessEvaluator {

    /// Evaluate `guess` against `answer`. Both are compared lowercased.
    /// Returns one `TileState` per character. If the lengths differ (which should
    /// never happen on a validated user path) returns all `.absent` of the guess
    /// length so callers stay crash-proof.
    static func evaluate(guess: String, answer: String) -> [TileState] {
        let g = Array(guess.lowercased())
        let a = Array(answer.lowercased())

        guard g.count == a.count else {
            return Array(repeating: .absent, count: g.count)
        }

        var result = Array(repeating: TileState.absent, count: g.count)

        // Build the remaining-letter multiset from the answer.
        var remaining: [Character: Int] = [:]
        for ch in a {
            remaining[ch, default: 0] += 1
        }

        // Pass 1: greens (exact position). Decrement the multiset for each green.
        for i in g.indices {
            if g[i] == a[i] {
                result[i] = .correct
                if let count = remaining[g[i]], count > 0 {
                    remaining[g[i]] = count - 1
                }
            }
        }

        // Pass 2: yellows, only while the letter's remaining count allows it.
        for i in g.indices where result[i] != .correct {
            let ch = g[i]
            if let count = remaining[ch], count > 0 {
                result[i] = .present
                remaining[ch] = count - 1
            } else {
                result[i] = .absent
            }
        }

        return result
    }
}
