import Foundation
import SwiftData
import Observation

/// One generated drill question.
struct DrillQuestion: Identifiable {
    let id = UUID()
    let verb: Verb
    let tense: Tense
    let person: Person
    let correctAnswer: String
    let choices: [String]   // for multiple-choice mode (includes correct)
}

/// Result of grading an answer.
struct GradeResult {
    let isCorrect: Bool
    let correctAnswer: String
    let given: String
}

/// Adaptive, mastery-weighted drill engine.
@Observable
final class DrillEngine {

    // Configuration (set at session start).
    private(set) var language: Language = .spanish
    private(set) var mode: AnswerMode = .type
    private(set) var accentStrict: Bool = false
    private(set) var sessionLength: Int = 10

    // Session state.
    private(set) var pool: [(verb: Verb, tense: Tense)] = []
    private(set) var current: DrillQuestion?
    private(set) var answered: Int = 0
    private(set) var correctCount: Int = 0
    private(set) var lastGrade: GradeResult?
    private(set) var startDate: Date = .now
    private(set) var isFinished: Bool = false

    /// Local mastery cache, mirrored to ItemStat on grade. key = ItemStat id.
    private var masteryCache: [String: Double] = [:]

    var progress: Double {
        sessionLength > 0 ? Double(answered) / Double(sessionLength) : 0
    }

    /// Begin a new session. Returns false if no items are available.
    @discardableResult
    func start(language: Language,
               mode: AnswerMode,
               accentStrict: Bool,
               sessionLength: Int,
               enabledTenses: Set<String>,
               verbs: [Verb],
               existingStats: [ItemStat]) -> Bool {
        self.language = language
        self.mode = mode
        self.accentStrict = accentStrict
        self.sessionLength = max(1, sessionLength)
        self.answered = 0
        self.correctCount = 0
        self.lastGrade = nil
        self.isFinished = false
        self.startDate = .now
        self.reviewItems = []

        // Build pool: every enabled verb × enabled tense in this language.
        let tenses = language.tenses.filter { enabledTenses.contains($0.rawValue) }
        var built: [(Verb, Tense)] = []
        for verb in verbs where verb.language == language {
            for tense in tenses {
                built.append((verb, tense))
            }
        }
        pool = built.map { (verb: $0.0, tense: $0.1) }

        // Seed mastery cache from existing stats.
        masteryCache.removeAll()
        for stat in existingStats {
            masteryCache[stat.id] = stat.mastery
        }

        guard !pool.isEmpty else {
            isFinished = true
            return false
        }
        current = nextQuestion()
        return true
    }

    /// Pick the next item, weighting weak (low-mastery) items more heavily.
    private func nextQuestion() -> DrillQuestion? {
        guard !pool.isEmpty else { return nil }

        // Weight = (1 - mastery) emphasized, with a floor so mastered items still appear.
        var weights: [Double] = []
        for item in pool {
            let key = ItemStat.makeID(language: language.rawValue,
                                      verb: item.verb.infinitive,
                                      tense: item.tense.rawValue)
            let mastery = masteryCache[key] ?? 0
            let weight = pow(1.0 - mastery, 2) + 0.08   // floor 0.08
            weights.append(weight)
        }

        let total = weights.reduce(0, +)
        var pickIndex = 0
        if total > 0 {
            var r = Double.random(in: 0..<total)
            for (i, w) in weights.enumerated() {
                if r < w { pickIndex = i; break }
                r -= w
            }
        }

        guard let chosen = pool[safe: pickIndex] else { return nil }
        let persons = language.persons
        let person = persons.randomElement() ?? (persons.first ?? .yo)
        let answer = ConjugationEngine.conjugate(chosen.verb, tense: chosen.tense, person: person)
        let choices = mode == .choice
            ? makeChoices(correct: answer, verb: chosen.verb, tense: chosen.tense, person: person)
            : []

        return DrillQuestion(verb: chosen.verb,
                             tense: chosen.tense,
                             person: person,
                             correctAnswer: answer,
                             choices: choices)
    }

    /// Build 4 plausible distractor choices (other persons / nearby forms).
    private func makeChoices(correct: String, verb: Verb, tense: Tense, person: Person) -> [String] {
        var options = Set<String>()
        options.insert(correct)

        // Distractors from other persons of the same verb×tense.
        for p in language.persons where p != person {
            options.insert(ConjugationEngine.conjugate(verb, tense: tense, person: p))
        }
        // Distractors from other tenses (same person).
        for t in language.tenses where t != tense {
            options.insert(ConjugationEngine.conjugate(verb, tense: t, person: person))
            if options.count >= 8 { break }
        }

        options.remove(correct)
        var distractors = Array(options).shuffled().prefix(3)
        if distractors.count < 3 {
            // Pad with simple stem variants if a verb has few distinct forms.
            distractors = Array(distractors)
        }
        var final = Array(distractors)
        final.append(correct)
        return final.shuffled()
    }

    /// Grade the given answer, update mastery, advance. Returns the grade.
    @discardableResult
    func submit(_ given: String, context: ModelContext) -> GradeResult? {
        guard let q = current else { return nil }

        let isCorrect: Bool
        if accentStrict {
            isCorrect = given.normalizedStrict == q.correctAnswer.normalizedStrict
        } else {
            isCorrect = given.foldedForComparison == q.correctAnswer.foldedForComparison
        }

        let result = GradeResult(isCorrect: isCorrect,
                                 correctAnswer: q.correctAnswer,
                                 given: given)
        lastGrade = result
        answered += 1
        if isCorrect {
            correctCount += 1
        } else {
            let label = "\(q.person.pronoun) · \(q.tense.displayName) · \(q.verb.infinitive) → \(q.correctAnswer)"
            reviewItems.append(label)
        }

        updateStat(question: q, isCorrect: isCorrect, context: context)

        if answered >= sessionLength {
            isFinished = true
            current = nil
        } else {
            current = nextQuestion()
        }
        return result
    }

    /// Update (or create) the ItemStat for this question.
    private func updateStat(question q: DrillQuestion, isCorrect: Bool, context: ModelContext) {
        let key = ItemStat.makeID(language: language.rawValue,
                                  verb: q.verb.infinitive,
                                  tense: q.tense.rawValue)
        let descriptor = FetchDescriptor<ItemStat>(predicate: #Predicate { $0.id == key })
        let stat: ItemStat
        if let existing = (try? context.fetch(descriptor))?.first {
            stat = existing
        } else {
            stat = ItemStat(verbInfinitive: q.verb.infinitive,
                            language: language.rawValue,
                            tense: q.tense.rawValue)
            context.insert(stat)
        }

        stat.attempts += 1
        if isCorrect { stat.correct += 1 }
        stat.lastSeen = .now

        // Smoothed mastery update: move toward 1 on success, toward 0 on miss.
        let target = isCorrect ? 1.0 : 0.0
        let rate = isCorrect ? 0.30 : 0.40
        stat.mastery = min(1.0, max(0.0, stat.mastery + (target - stat.mastery) * rate))

        masteryCache[key] = stat.mastery
        try? context.save()
    }

    /// Persist a completed session record.
    func finishSession(context: ModelContext) {
        let elapsed = Int(Date.now.timeIntervalSince(startDate))
        let session = DrillSession(language: language.rawValue,
                                   mode: mode.rawValue,
                                   total: answered,
                                   correct: correctCount,
                                   durationSeconds: max(0, elapsed))
        context.insert(session)
        try? context.save()
    }

    /// Items missed this session (for the end summary "to review" list).
    private(set) var reviewItems: [String] = []
}
