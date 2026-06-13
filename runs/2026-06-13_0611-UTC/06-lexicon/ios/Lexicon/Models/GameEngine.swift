import Foundation

enum LetterState: String, Codable {
    case empty, filled, correct, present, absent
}

enum WordGame {
    static let wordLength = 5
    static let maxRows = 6

    /// Classic two-pass scoring that respects duplicate letters.
    static func evaluate(guess: String, answer: String) -> [LetterState] {
        let g = Array(guess.lowercased())
        let a = Array(answer.lowercased())
        guard g.count == wordLength, a.count == wordLength else {
            return Array(repeating: .absent, count: wordLength)
        }
        var result = [LetterState](repeating: .absent, count: wordLength)
        var counts: [Character: Int] = [:]
        for c in a { counts[c, default: 0] += 1 }
        for i in 0..<wordLength where g[i] == a[i] {
            result[i] = .correct
            counts[g[i]]? -= 1
        }
        for i in 0..<wordLength where result[i] != .correct {
            if let remaining = counts[g[i]], remaining > 0 {
                result[i] = .present
                counts[g[i]]? -= 1
            }
        }
        return result
    }

    static func dayKey(_ date: Date = .now) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(fromDayKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private static func fnv(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { hash ^= UInt64(b); hash = hash &* 0x100000001b3 }
        return hash
    }

    static func dailyAnswer(for date: Date = .now) -> String {
        let words = WordList.words
        guard !words.isEmpty else { return "world" }
        return words[Int(fnv(dayKey(date)) % UInt64(words.count))]
    }

    static func randomAnswer() -> String {
        WordList.words.randomElement() ?? "world"
    }

    /// Aggregate the best known state for each keyboard letter.
    static func keyboardStates(rows: [[LetterState]], guesses: [String]) -> [Character: LetterState] {
        var map: [Character: LetterState] = [:]
        let rank: [LetterState: Int] = [.absent: 1, .present: 2, .correct: 3]
        for (gi, guess) in guesses.enumerated() where gi < rows.count {
            let letters = Array(guess.lowercased())
            for (li, state) in rows[gi].enumerated() where li < letters.count {
                let c = letters[li]
                if (rank[state] ?? 0) > (rank[map[c] ?? .empty] ?? 0) {
                    map[c] = state
                }
            }
        }
        return map
    }
}
