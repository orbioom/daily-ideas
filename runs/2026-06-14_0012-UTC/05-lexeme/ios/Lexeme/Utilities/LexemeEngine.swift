import Foundation

/// Pure, testable logic for Lexeme: word-of-the-day selection, spaced repetition
/// scheduling, quiz generation, and statistics. No SwiftUI, no SwiftData writes —
/// callers feed in progress snapshots and apply the returned updates.
enum LexemeEngine {

    // MARK: - Spaced repetition

    /// Days until the next review for each mastery level 0...5.
    static let intervals: [Int] = [0, 1, 3, 7, 16, 40]
    static let maxLevel = 5

    /// Returns the next review date for a level, measured from `now`.
    static func nextReviewDate(forLevel level: Int, from now: Date = Date()) -> Date {
        let clamped = min(max(level, 0), intervals.count - 1)
        let days = intervals[clamped]
        if days == 0 {
            // Brand-new or just-missed: due again very soon (10 minutes).
            return now.addingTimeInterval(10 * 60)
        }
        return Calendar.current.date(byAdding: .day, value: days, to: now) ?? now.addingTimeInterval(Double(days) * 86_400)
    }

    /// The new level after grading. Correct climbs one rung; wrong drops one (floor 0).
    static func updatedLevel(current: Int, correct: Bool) -> Int {
        if correct { return min(current + 1, maxLevel) }
        return max(current - 1, 0)
    }

    /// A word is mastered (learned) once it reaches the top level.
    static func isMastered(level: Int) -> Bool { level >= maxLevel }

    /// Whether a progress row is due for review at `now`.
    static func isDue(_ p: WordProgress, now: Date = Date()) -> Bool {
        p.nextReview <= now
    }

    // MARK: - Word of the day

    /// Deterministic daily word: hashes the yyyy-MM-dd string, indexes into the
    /// not-yet-learned pool (falling back to the full bank if everything is learned).
    /// Stable for the whole calendar day.
    static func wordOfTheDay(on date: Date = Date(),
                             learnedIDs: Set<String>,
                             bank: [VocabWord] = WordBank.all) -> VocabWord? {
        guard !bank.isEmpty else { return nil }
        let pool = bank.filter { !learnedIDs.contains($0.id) }
        let candidates = pool.isEmpty ? bank : pool
        guard !candidates.isEmpty else { return nil }
        let key = dayKey(date)
        let h = stableHash(key)
        let index = Int(h % UInt64(candidates.count))
        // index is always in 0..<count by construction.
        return candidates[index]
    }

    /// yyyy-MM-dd in the current calendar, used as the daily seed.
    static func dayKey(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2000, m = c.month ?? 1, d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// FNV-1a 64-bit — stable across launches (unlike Swift's `Hashable`).
    static func stableHash(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    // MARK: - Quiz generation

    /// Builds a quiz question for `word` in `mode`, drawing distractors from the
    /// same part of speech / similar tier where possible. `typedFillBlank` makes
    /// fill-in-the-blank a typed prompt rather than multiple choice.
    static func makeQuestion(for word: VocabWord,
                             mode: QuizMode,
                             bank: [VocabWord] = WordBank.all,
                             typedFillBlank: Bool = false) -> QuizQuestion? {
        switch mode {
        case .definitionToWord:
            let distractors = distractorWords(for: word, bank: bank, count: 3).map { $0.word }
            guard distractors.count == 3 else { return nil }
            let options = (distractors + [word.word]).shuffled()
            return QuizQuestion(mode: mode, word: word,
                                prompt: word.definition,
                                options: options, answer: word.word, isTyped: false)

        case .wordToDefinition:
            let distractors = distractorWords(for: word, bank: bank, count: 3).map { $0.definition }
            guard distractors.count == 3 else { return nil }
            let options = (distractors + [word.definition]).shuffled()
            return QuizQuestion(mode: mode, word: word,
                                prompt: word.word,
                                options: options, answer: word.definition, isTyped: false)

        case .synonymMatch:
            guard let correct = word.synonyms.first(where: { !$0.isEmpty }) else { return nil }
            // Distractors: synonyms belonging to OTHER words (so they're plausible vocab,
            // but not actual synonyms of this word).
            let mine = Set((word.synonyms + [word.word]).map { $0.lowercased() })
            var pool: [String] = []
            for w in bank where w.id != word.id {
                for syn in w.synonyms where !mine.contains(syn.lowercased()) {
                    pool.append(syn)
                }
            }
            let distractors = Array(Set(pool)).shuffled().prefix(3)
            guard distractors.count == 3 else { return nil }
            let options = (Array(distractors) + [correct]).shuffled()
            return QuizQuestion(mode: mode, word: word,
                                prompt: word.word,
                                options: options, answer: correct, isTyped: false)

        case .fillBlank:
            let blanked = blankedExample(for: word)
            guard blanked != word.example else { return nil } // word must appear
            if typedFillBlank {
                return QuizQuestion(mode: mode, word: word,
                                    prompt: blanked, options: [], answer: word.word, isTyped: true)
            }
            let distractors = distractorWords(for: word, bank: bank, count: 3).map { $0.word }
            guard distractors.count == 3 else { return nil }
            let options = (distractors + [word.word]).shuffled()
            return QuizQuestion(mode: mode, word: word,
                                prompt: blanked, options: options, answer: word.word, isTyped: false)
        }
    }

    /// Replaces the (first, case-insensitive) occurrence of the word in its example
    /// with a blank, preserving surrounding text. Returns the original if not found.
    static func blankedExample(for word: VocabWord) -> String {
        let example = word.example
        let lowerEx = example.lowercased()
        let lowerWord = word.word.lowercased()
        guard let range = lowerEx.range(of: lowerWord) else { return example }
        // Map the lowercase range back to the original string by offset.
        let start = lowerEx.distance(from: lowerEx.startIndex, to: range.lowerBound)
        let length = word.word.count
        guard let s = example.index(example.startIndex, offsetBy: start, limitedBy: example.endIndex),
              let e = example.index(s, offsetBy: length, limitedBy: example.endIndex) else {
            return example
        }
        return example.replacingCharacters(in: s..<e, with: "______")
    }

    /// Picks `count` plausible distractor words: same part of speech first, then
    /// same tier, then anything — never the word itself, never duplicates.
    static func distractorWords(for word: VocabWord, bank: [VocabWord], count: Int) -> [VocabWord] {
        let others = bank.filter { $0.id != word.id }
        var chosen: [VocabWord] = []
        var used = Set<String>([word.id])

        func draw(from pool: [VocabWord]) {
            for w in pool.shuffled() where chosen.count < count && !used.contains(w.id) {
                chosen.append(w); used.insert(w.id)
            }
        }
        // Tier 1: same POS AND same tier.
        draw(from: others.filter { $0.partOfSpeech == word.partOfSpeech && $0.tier == word.tier })
        // Tier 2: same POS, any tier.
        if chosen.count < count { draw(from: others.filter { $0.partOfSpeech == word.partOfSpeech }) }
        // Tier 3: anything.
        if chosen.count < count { draw(from: others) }
        return Array(chosen.prefix(count))
    }

    /// Builds an adaptive review session: due words first (oldest due first),
    /// then unseen words to introduce, capped at `limit`. Modes are assigned per
    /// word from `allowedModes`, but only modes the word can actually support.
    static func buildSession(progress: [WordProgress],
                             allowedModes: [QuizMode],
                             limit: Int,
                             bank: [VocabWord] = WordBank.all,
                             typedFillBlank: Bool,
                             now: Date = Date()) -> [QuizQuestion] {
        guard limit > 0, !allowedModes.isEmpty else { return [] }
        let progressByID = Dictionary(progress.map { ($0.wordID, $0) }, uniquingKeysWith: { a, _ in a })

        // Due words, oldest first.
        let due = progress
            .filter { isDue($0, now: now) }
            .sorted { $0.nextReview < $1.nextReview }
            .compactMap { WordBank.word(id: $0.wordID) }

        // Unseen words to introduce (no progress row yet), in bank order.
        let unseen = bank.filter { progressByID[$0.id] == nil }

        var ordered: [VocabWord] = []
        var seenIDs = Set<String>()
        for w in due + unseen where !seenIDs.contains(w.id) {
            ordered.append(w); seenIDs.insert(w.id)
            if ordered.count >= limit { break }
        }
        // If still short (everything reviewed & introduced), fold in lowest-level words.
        if ordered.count < limit {
            let extra = progress
                .sorted { $0.level < $1.level }
                .compactMap { WordBank.word(id: $0.wordID) }
            for w in extra where !seenIDs.contains(w.id) {
                ordered.append(w); seenIDs.insert(w.id)
                if ordered.count >= limit { break }
            }
        }

        var questions: [QuizQuestion] = []
        var modeRotation = allowedModes.shuffled()
        var rotIndex = 0
        for w in ordered {
            // Try modes in a rotating order until one can be built for this word.
            var built: QuizQuestion?
            for offset in 0..<modeRotation.count {
                let mode = modeRotation[(rotIndex + offset) % modeRotation.count]
                let supported = supportedModes(for: w, within: allowedModes)
                guard supported.contains(mode) else { continue }
                if let q = makeQuestion(for: w, mode: mode, bank: bank, typedFillBlank: typedFillBlank) {
                    built = q; break
                }
            }
            // Fallback: any supported mode that builds.
            if built == nil {
                for mode in supportedModes(for: w, within: allowedModes) {
                    if let q = makeQuestion(for: w, mode: mode, bank: bank, typedFillBlank: typedFillBlank) {
                        built = q; break
                    }
                }
            }
            if let q = built { questions.append(q) }
            rotIndex += 1
        }
        return questions
    }

    /// Which of the allowed modes a given word can actually support
    /// (synonym match needs a synonym; fill-blank needs the word in its example).
    static func supportedModes(for word: VocabWord, within allowed: [QuizMode]) -> [QuizMode] {
        allowed.filter { mode in
            switch mode {
            case .synonymMatch: return !word.synonyms.isEmpty
            case .fillBlank:    return blankedExample(for: word) != word.example
            default:            return true
            }
        }
    }

    // MARK: - Statistics

    /// How many distinct progress rows are marked learned.
    static func learnedCount(_ progress: [WordProgress]) -> Int {
        progress.filter { $0.learned }.count
    }

    /// Count of progress rows at each mastery level 0...5.
    static func masteryDistribution(_ progress: [WordProgress]) -> [Int] {
        var buckets = Array(repeating: 0, count: maxLevel + 1)
        for p in progress {
            let l = min(max(p.level, 0), maxLevel)
            buckets[l] += 1
        }
        return buckets
    }

    /// Overall accuracy across all sessions (correct / total).
    static func overallAccuracy(_ sessions: [StudySession]) -> Double {
        let total = sessions.reduce(0) { $0 + $1.total }
        guard total > 0 else { return 0 }
        let correct = sessions.reduce(0) { $0 + $1.correct }
        return Double(correct) / Double(total)
    }

    /// Number of words due in each of the next `days` days (index 0 == today).
    static func dueForecast(_ progress: [WordProgress], days: Int = 7, now: Date = Date()) -> [Int] {
        guard days > 0 else { return [] }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let startOfToday = cal.startOfDay(for: now)
        var buckets = Array(repeating: 0, count: days)
        for p in progress {
            // Overdue or due today both count toward today (index 0).
            if p.nextReview <= now {
                buckets[0] += 1
                continue
            }
            let reviewDay = cal.startOfDay(for: p.nextReview)
            let delta = cal.dateComponents([.day], from: startOfToday, to: reviewDay).day ?? 0
            if delta >= 0 && delta < days {
                buckets[delta] += 1
            }
        }
        return buckets
    }

    /// Current consecutive-day study streak (counting today or yesterday as alive).
    static func streak(_ sessions: [StudySession], now: Date = Date()) -> Int {
        guard !sessions.isEmpty else { return 0 }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        // Distinct study days, most recent first.
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) })
            .sorted(by: >)
        guard let mostRecent = days.first else { return 0 }
        let today = cal.startOfDay(for: now)
        let daysSinceLast = cal.dateComponents([.day], from: mostRecent, to: today).day ?? 0
        // Streak is broken if the last study day is more than a day ago.
        guard daysSinceLast <= 1 else { return 0 }

        var streak = 0
        var cursor = mostRecent
        let daySet = Set(days)
        while daySet.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Words learned per day, for the line/bar chart, over the last `days` days.
    /// Derived from each learned word's `lastSeen` (a reasonable "learned on" proxy).
    static func learnedOverTime(_ progress: [WordProgress], days: Int = 30, now: Date = Date()) -> [(date: Date, count: Int)] {
        guard days > 0 else { return [] }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let today = cal.startOfDay(for: now)
        var byDay: [Date: Int] = [:]
        for p in progress where p.learned {
            let when = p.lastSeen ?? now
            let day = cal.startOfDay(for: when)
            byDay[day, default: 0] += 1
        }
        var result: [(date: Date, count: Int)] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            result.append((date: day, count: byDay[day] ?? 0))
        }
        return result
    }
}
