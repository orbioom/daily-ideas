import Foundation

enum WordEngine {
    static let maxGuesses = 6
    static let wordLength = 5

    /// Evaluate a guess against the answer with correct duplicate-letter rules
    /// (two-pass: greens first, then yellows consume remaining letter counts).
    static func evaluate(_ guess: String, answer: String) -> [LetterState] {
        let g = Array(guess.lowercased())
        let a = Array(answer.lowercased())
        guard g.count == a.count else { return Array(repeating: .absent, count: g.count) }

        var result = [LetterState](repeating: .absent, count: g.count)
        var counts: [Character: Int] = [:]
        for ch in a { counts[ch, default: 0] += 1 }

        // Pass 1: exact matches.
        for i in g.indices where g[i] == a[i] {
            result[i] = .correct
            counts[g[i], default: 0] -= 1
        }
        // Pass 2: present-but-misplaced, limited by remaining counts.
        for i in g.indices where result[i] != .correct {
            if counts[g[i], default: 0] > 0 {
                result[i] = .present
                counts[g[i], default: 0] -= 1
            }
        }
        return result
    }

    /// Best-known state per keyboard letter across all guesses.
    static func keyboardStates(guesses: [String], answer: String) -> [Character: LetterState] {
        var map: [Character: LetterState] = [:]
        for guess in guesses {
            let states = evaluate(guess, answer: answer)
            for (i, ch) in Array(guess.lowercased()).enumerated() where i < states.count {
                if states[i].rank > (map[ch]?.rank ?? 0) { map[ch] = states[i] }
            }
        }
        return map
    }

    /// Hard-mode validation: every revealed hint must be honored by the guess.
    /// Returns an error message if the guess violates a known clue.
    static func hardModeViolation(_ guess: String, previousGuesses: [String], answer: String) -> String? {
        let g = Array(guess.lowercased())
        for prev in previousGuesses {
            let states = evaluate(prev, answer: answer)
            let p = Array(prev.lowercased())
            for i in states.indices {
                if states[i] == .correct && (i >= g.count || g[i] != p[i]) {
                    return "Position \(i + 1) must be \(String(p[i]).uppercased())"
                }
            }
            for i in states.indices where states[i] == .present {
                if !g.contains(p[i]) {
                    return "Guess must contain \(String(p[i]).uppercased())"
                }
            }
        }
        return nil
    }

    // MARK: - Daily answer

    static func dailyKey(for date: Date = .now) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Deterministic daily answer: hash the date into the answers list.
    static func dailyAnswer(for date: Date = .now) -> String {
        let key = dailyKey(for: date)
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in key.utf8 { hash ^= UInt64(byte); hash = hash &* 0x100000001b3 }
        let list = WordList.answers
        guard !list.isEmpty else { return "about" }
        return list[Int(hash % UInt64(list.count))]
    }

    static func randomAnswer() -> String {
        WordList.answers.randomElement() ?? "about"
    }

    // MARK: - Share grid

    static func shareGrid(_ game: WordGame, dayNumber: Int? = nil) -> String {
        let header: String
        if game.mode == .daily, let n = dayNumber {
            header = "Lexic #\(n) \(game.state == .won ? "\(game.guessCount)/6" : "X/6")\(game.hardMode ? "*" : "")"
        } else {
            header = "Lexic \(game.state == .won ? "\(game.guessCount)/6" : "X/6")\(game.hardMode ? "*" : "")"
        }
        let rows = game.guesses.map { guess in
            evaluate(guess, answer: game.answer).map(\.emoji).joined()
        }
        return ([header, ""] + rows).joined(separator: "\n")
    }
}
