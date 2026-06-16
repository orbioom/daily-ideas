import Foundation

/// One question presented in a graded session.
///
/// For ordinary questions this is multiple-choice (`choices` populated, `correctIndex` set).
/// For `varies` questions there is no auto-gradable answer, so it is presented as a
/// self-check ("Did you know it?") — `choices` is empty and `correctIndex` is nil.
struct ExamItem: Identifiable, Hashable {
    let id = UUID()
    let question: CivicsQuestion
    let choices: [String]
    let correctIndex: Int?

    var isSelfCheck: Bool { correctIndex == nil }
}

/// The user's response to a single exam item.
struct ExamAnswer: Hashable {
    /// Index chosen for multiple-choice items; nil if skipped.
    var selectedIndex: Int?
    /// For self-check (`varies`) items: did the user say they knew it?
    var knewIt: Bool?

    var isAnswered: Bool { selectedIndex != nil || knewIt != nil }
}

/// Pure, deterministic-where-possible logic for building exam item sets and
/// generating plausible multiple-choice distractors.
enum ExamEngine {

    /// Errors that can surface while building a session (all recoverable).
    enum BuildError: LocalizedError {
        case notEnoughQuestions(needed: Int, available: Int)
        case emptyPool

        var errorDescription: String? {
            switch self {
            case .notEnoughQuestions(let needed, let available):
                return "Not enough questions yet (need \(needed), found \(available))."
            case .emptyPool:
                return "There are no questions to study in this set right now."
            }
        }
    }

    /// Build a set of exam items for the given mode.
    ///
    /// - Parameters:
    ///   - mode: the session mode.
    ///   - category: required when `mode == .category`.
    ///   - stats: latest per-question stats (used by `.reviewFlagged` and `.adaptive`).
    ///   - rng: random source (injectable for tests / determinism).
    static func buildItems(mode: ExamMode,
                           category: CivicsCategory? = nil,
                           stats: [Int: QuestionStat] = [:],
                           rng: inout RandomNumberGenerator) throws -> [ExamItem] {
        let pool: [CivicsQuestion]
        let count: Int

        switch mode {
        case .mock:
            pool = CivicsContent.questions
            count = 10
        case .quick:
            pool = CivicsContent.questions
            count = 5
        case .category:
            guard let category else { throw BuildError.emptyPool }
            pool = CivicsContent.questions(in: category)
            count = min(10, pool.count)
        case .reviewFlagged:
            let flagged = CivicsContent.questions.filter { q in
                guard let s = stats[q.number] else { return false }
                return s.isFlagged || (s.timesSeen > 0 && s.accuracy < 0.5)
            }
            pool = flagged
            count = min(10, max(1, flagged.count))
        case .adaptive:
            pool = CivicsContent.questions
            count = 10
        }

        guard !pool.isEmpty else { throw BuildError.emptyPool }

        let selected: [CivicsQuestion]
        if mode == .adaptive {
            selected = weightedSelection(from: pool, count: count, stats: stats, rng: &rng)
        } else {
            selected = Array(pool.shuffled(using: &rng).prefix(count))
        }

        guard !selected.isEmpty else { throw BuildError.emptyPool }

        // Explicit loop (not map) so we can thread the inout RNG without capturing
        // it inside an escaping closure.
        var built: [ExamItem] = []
        built.reserveCapacity(selected.count)
        for question in selected {
            built.append(makeItem(for: question, rng: &rng))
        }
        return built
    }

    /// Build a single exam item: multiple choice for normal questions,
    /// self-check for `varies` questions.
    static func makeItem(for question: CivicsQuestion,
                         rng: inout RandomNumberGenerator) -> ExamItem {
        guard !question.varies, let correct = question.acceptableAnswers.first else {
            return ExamItem(question: question, choices: [], correctIndex: nil)
        }

        let wrongChoices = distractors(for: question, count: 3, rng: &rng)

        // If we couldn't gather any distractors (tiny pool), degrade gracefully
        // to a self-check rather than presenting a single-option question.
        guard !wrongChoices.isEmpty else {
            return ExamItem(question: question, choices: [], correctIndex: nil)
        }

        var choices = wrongChoices
        let insertAt = Int.random(in: 0...choices.count, using: &rng)
        choices.insert(correct, at: insertAt)
        return ExamItem(question: question, choices: choices, correctIndex: insertAt)
    }

    /// Gather plausible distractors from OTHER questions' answers, preferring the
    /// same category, then widening to all questions if needed. Guards small pools.
    static func distractors(for question: CivicsQuestion,
                            count: Int,
                            rng: inout RandomNumberGenerator) -> [String] {
        let correctSet = Set(question.acceptableAnswers.map(normalize))

        func candidates(sameCategoryOnly: Bool) -> [String] {
            var seen = Set<String>(correctSet)
            var result: [String] = []
            for other in CivicsContent.questions where other.number != question.number {
                if other.varies { continue }
                if sameCategoryOnly && other.category != question.category { continue }
                for ans in other.acceptableAnswers {
                    let key = normalize(ans)
                    if seen.contains(key) { continue }
                    seen.insert(key)
                    result.append(ans)
                }
            }
            return result
        }

        var pool = candidates(sameCategoryOnly: true)
        if pool.count < count {
            // Widen to all categories to fill out the choices.
            let extra = candidates(sameCategoryOnly: false)
            for e in extra where !pool.contains(where: { normalize($0) == normalize(e) }) {
                pool.append(e)
            }
        }

        return Array(pool.shuffled(using: &rng).prefix(count))
    }

    /// Weighted selection favoring low-mastery questions for adaptive mode.
    static func weightedSelection(from pool: [CivicsQuestion],
                                  count: Int,
                                  stats: [Int: QuestionStat],
                                  rng: inout RandomNumberGenerator) -> [CivicsQuestion] {
        guard count > 0 else { return [] }
        var remaining = pool
        var chosen: [CivicsQuestion] = []
        let target = min(count, remaining.count)

        while chosen.count < target && !remaining.isEmpty {
            // Weight = (1 - mastery) + small floor so every question can appear.
            let weights = remaining.map { q -> Double in
                let mastery = stats[q.number]?.mastery ?? 0
                return (1.0 - mastery) + 0.15
            }
            let totalWeight = weights.reduce(0, +)
            guard totalWeight > 0 else {
                // Degenerate: just take whatever's left.
                chosen.append(contentsOf: remaining.prefix(target - chosen.count))
                break
            }
            var roll = Double.random(in: 0..<totalWeight, using: &rng)
            var pickedIndex = remaining.count - 1
            for (i, w) in weights.enumerated() {
                roll -= w
                if roll <= 0 { pickedIndex = i; break }
            }
            chosen.append(remaining.remove(at: pickedIndex))
        }
        return chosen
    }

    /// Whether a typed/spoken answer string matches any acceptable answer (loose match).
    static func isCorrect(_ input: String, for question: CivicsQuestion) -> Bool {
        let normalizedInput = normalize(input)
        guard !normalizedInput.isEmpty else { return false }
        return question.acceptableAnswers.contains { acceptable in
            let a = normalize(acceptable)
            return a == normalizedInput
                || a.contains(normalizedInput)
                || normalizedInput.contains(a)
        }
    }

    /// Lowercase, strip punctuation/parenthetical hints, and collapse whitespace.
    static func normalize(_ s: String) -> String {
        let lowered = s.lowercased()
        let stripped = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == " " {
                return Character(scalar)
            }
            return " "
        }
        let joined = String(stripped)
        return joined.split(separator: " ").joined(separator: " ")
    }
}
