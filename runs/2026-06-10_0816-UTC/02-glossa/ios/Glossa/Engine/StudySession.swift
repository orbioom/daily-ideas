import Foundation
import Observation

enum QuestionMode {
    case multipleChoice   // recognition: target shown, pick the meaning
    case typed            // production: meaning shown, type the target
}

struct StudyQuestion: Identifiable {
    let id = UUID()
    let card: Card
    let mode: QuestionMode
    let options: [String]      // multiple choice only, shuffled, includes answer
    let isRelearn: Bool        // second pass over a missed card (not re-graded)
}

/// Drives one study run over a deck's due cards. Grades against the Leitner
/// engine on the first pass; missed cards come back once for practice.
@Observable
final class StudySession: Identifiable {
    let id = UUID()
    let deckName: String
    let languageCode: String
    let requireArticle: Bool

    private(set) var queue: [StudyQuestion]
    private(set) var index = 0
    private(set) var correctCount = 0
    private(set) var missedCount = 0
    private(set) var finished = false

    /// Set after each answer; cleared on advance.
    private(set) var lastVerdict: AnswerVerdict?

    init(deck: Deck, dueCards: [Card], maxCards: Int, typedEnabled: Bool, requireArticle: Bool) {
        deckName = deck.name
        languageCode = deck.languageCode
        self.requireArticle = requireArticle
        let all = deck.cards
        let picked = Array(dueCards.shuffled().prefix(max(1, maxCards)))
        queue = picked.map { card in
            let mode: QuestionMode = (typedEnabled && card.box >= 3) ? .typed : .multipleChoice
            let options = mode == .multipleChoice
                ? (LeitnerEngine.distractors(for: card, in: all, showingFront: true) + [card.back]).shuffled()
                : []
            return StudyQuestion(card: card, mode: mode, options: options, isRelearn: false)
        }
    }

    var current: StudyQuestion? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    var progress: Double {
        queue.isEmpty ? 0 : Double(index) / Double(queue.count)
    }

    var total: Int { queue.count }

    /// Multiple-choice answer.
    func answer(choice: String) {
        guard let q = current, lastVerdict == nil else { return }
        let correct = choice == q.card.back
        lastVerdict = correct ? .correct : .wrong(expected: q.card.back)
        apply(correct: correct, to: q)
    }

    /// Typed answer.
    func answer(typed: String) {
        guard let q = current, lastVerdict == nil else { return }
        let verdict = LeitnerEngine.check(answer: typed, against: q.card.front,
                                          languageCode: languageCode,
                                          requireArticle: requireArticle)
        lastVerdict = verdict
        let correct: Bool
        switch verdict {
        case .correct, .almost: correct = true
        case .wrong: correct = false
        }
        apply(correct: correct, to: q)
    }

    private func apply(correct: Bool, to q: StudyQuestion) {
        if !q.isRelearn {
            LeitnerEngine.grade(card: q.card, correct: correct)
            if correct { correctCount += 1 } else { missedCount += 1 }
        }
        if !correct && !q.isRelearn {
            // One practice pass at the end, multiple choice for gentleness.
            let opts = (LeitnerEngine.distractors(for: q.card, in: q.card.deck?.cards ?? [], showingFront: true) + [q.card.back]).shuffled()
            queue.append(StudyQuestion(card: q.card, mode: .multipleChoice, options: opts, isRelearn: true))
        }
    }

    func advance() {
        guard lastVerdict != nil else { return }
        lastVerdict = nil
        index += 1
        if index >= queue.count { finished = true }
    }
}
