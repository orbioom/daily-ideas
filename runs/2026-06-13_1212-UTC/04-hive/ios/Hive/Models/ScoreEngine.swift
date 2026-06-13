import Foundation

/// A rank tier, expressed as a percentage threshold of a puzzle's max score.
/// Thresholds mirror the classic NYT Spelling Bee progression.
struct Rank: Identifiable, Hashable {
    let name: String
    let fraction: Double   // 0...1 of max score
    var id: String { name }
}

/// Scoring, ranking, and word validation — pure, deterministic, crash-proof.
enum ScoreEngine {
    static let ranks: [Rank] = [
        Rank(name: "Beginner",    fraction: 0.00),
        Rank(name: "Good Start",  fraction: 0.02),
        Rank(name: "Moving Up",   fraction: 0.05),
        Rank(name: "Good",        fraction: 0.08),
        Rank(name: "Solid",       fraction: 0.15),
        Rank(name: "Nice",        fraction: 0.25),
        Rank(name: "Great",       fraction: 0.40),
        Rank(name: "Amazing",     fraction: 0.50),
        Rank(name: "Genius",      fraction: 0.70)
    ]

    /// The score for a single accepted word.
    /// 4-letter word = 1 point; longer = its length; pangram adds a +7 bonus.
    static func score(for word: String, isPangram: Bool) -> Int {
        let len = word.count
        guard len >= 4 else { return 0 }
        let base = len == 4 ? 1 : len
        return base + (isPangram ? 7 : 0)
    }

    /// The maximum reachable score: every answer scored.
    static func maxScore(_ puzzle: Puzzle) -> Int {
        puzzle.answers.reduce(0) { total, w in
            total + score(for: w, isPangram: puzzle.isPangram(w))
        }
    }

    /// The total score for a set of found words within a puzzle.
    static func currentScore(found: [String], in puzzle: Puzzle) -> Int {
        found.reduce(0) { total, w in
            total + score(for: w, isPangram: puzzle.isPangram(w))
        }
    }

    /// The highest rank reached at `score` out of `max`.
    static func rank(for score: Int, max: Int) -> Rank {
        guard max > 0 else { return ranks[0] }
        let frac = Double(score) / Double(max)
        var best = ranks[0]
        for r in ranks where frac >= r.fraction { best = r }
        return best
    }

    /// The next rank above the current one, or nil at the top.
    static func nextRank(for score: Int, max: Int) -> Rank? {
        guard max > 0 else { return ranks.count > 1 ? ranks[1] : nil }
        let frac = Double(score) / Double(max)
        return ranks.first { $0.fraction > frac }
    }

    /// Points needed to reach the next rank (0 if already at the top).
    static func pointsToNext(score: Int, max: Int) -> Int {
        guard max > 0, let next = nextRank(for: score, max: max) else { return 0 }
        let target = Int((next.fraction * Double(max)).rounded(.up))
        return Swift.max(0, target - score)
    }

    /// True once the player's score reaches the Genius threshold.
    static func isGenius(score: Int, max: Int) -> Bool {
        guard max > 0, let genius = ranks.last else { return false }
        return Double(score) / Double(max) >= genius.fraction
    }

    // MARK: - Validation

    enum Result: Equatable {
        case tooShort
        case missingCenter
        case badLetters
        case notInWordList
        case alreadyFound
        case accepted(word: String, score: Int, isPangram: Bool)
    }

    /// Validate a raw entry against a puzzle and the words already found.
    /// Case-insensitive; never crashes on empty or odd input.
    static func validate(_ entry: String, puzzle: Puzzle, alreadyFound: [String]) -> Result {
        let word = entry.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count >= 4 else { return .tooShort }
        guard word.contains(puzzle.center) else { return .missingCenter }
        let allowed = Set(puzzle.letters)
        guard word.allSatisfy({ allowed.contains($0) }) else { return .badLetters }
        if alreadyFound.contains(word) { return .alreadyFound }
        guard puzzle.answers.contains(word) else { return .notInWordList }
        let pangram = puzzle.isPangram(word)
        return .accepted(word: word, score: score(for: word, isPangram: pangram), isPangram: pangram)
    }
}
