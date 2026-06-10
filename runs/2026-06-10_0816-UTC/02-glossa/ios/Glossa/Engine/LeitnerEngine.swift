import Foundation

enum AnswerVerdict: Equatable {
    case correct
    case almost(expected: String)   // one typo away — counts as correct
    case wrong(expected: String)
}

/// Pure Leitner-box scheduling plus tolerant answer checking.
enum LeitnerEngine {

    static let boxCount = 5
    /// Days until the next review per box (box 1 reviews immediately).
    static let intervals: [Int] = [0, 1, 3, 7, 14]

    static func interval(forBox box: Int) -> Int {
        let i = min(max(box, 1), boxCount) - 1
        return intervals[i]
    }

    /// Applies one graded answer to a card and reschedules it.
    static func grade(card: Card, correct: Bool, now: Date = .now, calendar: Calendar = .current) {
        card.reviews += 1
        card.lastReviewed = now
        if correct {
            card.box = min(boxCount, card.box + 1)
        } else {
            card.box = 1
            card.lapses += 1
        }
        let days = interval(forBox: card.box)
        let base = calendar.startOfDay(for: now)
        card.dueDate = calendar.date(byAdding: .day, value: days, to: base) ?? now
    }

    // MARK: Answer checking

    /// Case-, diacritic-, and whitespace-insensitive normalization.
    static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }

    /// Strips a leading article ("el ", "die ", "l'", …) for relaxed checking.
    static func stripArticle(_ s: String, languageCode: String) -> String {
        var t = normalize(s)
        if t.hasPrefix("l'") { t = String(t.dropFirst(2)) }
        for article in Lexicon.articles(for: languageCode) {
            let prefix = article + " "
            if t.hasPrefix(prefix) {
                return String(t.dropFirst(prefix.count))
            }
        }
        return t
    }

    static func check(answer: String, against expected: String,
                      languageCode: String, requireArticle: Bool) -> AnswerVerdict {
        let a = normalize(answer)
        let e = normalize(expected)
        guard !a.isEmpty else { return .wrong(expected: expected) }
        if a == e { return .correct }

        if !requireArticle {
            let aStripped = stripArticle(answer, languageCode: languageCode)
            let eStripped = stripArticle(expected, languageCode: languageCode)
            if aStripped == eStripped { return .correct }
            if levenshtein(aStripped, eStripped) == 1 { return .almost(expected: expected) }
        }
        if levenshtein(a, e) == 1 { return .almost(expected: expected) }
        return .wrong(expected: expected)
    }

    /// Classic dynamic-programming edit distance; inputs are short words.
    static func levenshtein(_ a: String, _ b: String) -> Int {
        let aa = Array(a), bb = Array(b)
        if aa.isEmpty { return bb.count }
        if bb.isEmpty { return aa.count }
        var prev = Array(0...bb.count)
        var cur = [Int](repeating: 0, count: bb.count + 1)
        for i in 1...aa.count {
            cur[0] = i
            for j in 1...bb.count {
                let cost = aa[i-1] == bb[j-1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j-1] + 1, prev[j-1] + cost)
            }
            swap(&prev, &cur)
        }
        return prev[bb.count]
    }

    /// Three plausible distractors for a multiple-choice question.
    static func distractors(for card: Card, in cards: [Card], showingFront: Bool) -> [String] {
        let pool = cards
            .filter { $0.persistentModelID != card.persistentModelID }
            .map { showingFront ? $0.back : $0.front }
        let unique = Array(Set(pool)).filter { $0 != (showingFront ? card.back : card.front) }
        return Array(unique.shuffled().prefix(3))
    }
}
