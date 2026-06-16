import SwiftUI
import SwiftData

/// Drives a single study session: current card, reveal state, grading, and the running summary.
@Observable
final class StudyViewModel {
    // Session inputs
    let mode: ReviewMode
    private let queue: [Card]
    private let distractorPool: [Card]

    // Session progress
    private(set) var index: Int = 0
    private(set) var isRevealed = false
    private(set) var finished = false

    // Running tally
    private(set) var reviewedCount = 0
    private(set) var correctCount = 0
    private(set) var gradeCounts: [Grade: Int] = [:]

    // Mode-specific scratch state
    private(set) var options: [String] = []
    private(set) var selectedOption: String? = nil
    var typedAnswer: String = ""
    private(set) var typedJudged = false
    private(set) var typedWasCorrect = false

    init(config: StudyConfig) {
        self.mode = config.mode
        self.queue = config.queue
        self.distractorPool = config.distractorPool
        prepareCurrent()
    }

    /// Total cards in the session.
    var total: Int { queue.count }

    /// 0...1 progress through the session.
    var progress: Double {
        guard total > 0 else { return 1 }
        return Double(min(index, total)) / Double(total)
    }

    var remaining: Int { max(0, total - index) }

    var currentCard: Card? {
        guard queue.indices.contains(index) else { return nil }
        return queue[index]
    }

    /// Retention for the session so far (% of graded cards that were not "Again").
    var retentionPercent: Int {
        guard reviewedCount > 0 else { return 0 }
        return Int((Double(correctCount) / Double(reviewedCount) * 100).rounded())
    }

    // MARK: - Flow

    /// Reveal the back (flip / type / MCQ reveal).
    func reveal() {
        isRevealed = true
    }

    /// MCQ: choose an option; reveals immediately.
    func chooseOption(_ option: String) {
        guard !isRevealed else { return }
        selectedOption = option
        isRevealed = true
    }

    /// Type mode: submit the typed answer and judge it.
    func submitTyped() {
        guard let card = currentCard, !typedJudged else { return }
        typedWasCorrect = StudyQueue.answerMatches(typed: typedAnswer, card: card)
        typedJudged = true
        isRevealed = true
    }

    /// Whether a chosen MCQ option is the correct one.
    func optionIsCorrect(_ option: String) -> Bool {
        guard let card = currentCard else { return false }
        return StudyQueue.normalize(option) == StudyQueue.normalize(card.back)
    }

    /// Apply a grade to the current card, write SRS + log, and advance.
    /// `context` is the live model context; pass `nil` for previews/dry runs.
    func grade(_ grade: Grade, context: ModelContext?, hapticsEnabled: Bool) {
        guard let card = currentCard else { return }

        if mode.affectsSchedule {
            let result = SRSEngine.schedule(card: card, grade: grade)
            SRSEngine.apply(result, to: card)

            // Log against the card's own deck so cross-deck sessions stay correct.
            if let deck = card.deck {
                let log = ReviewLog(grade: grade, cardFront: card.front)
                log.deck = deck
                deck.logs.append(log)
                context?.insert(log)
            }
            try? context?.save()
        }

        reviewedCount += 1
        if grade.isCorrect { correctCount += 1 }
        gradeCounts[grade, default: 0] += 1

        Haptics.tap(enabled: hapticsEnabled)
        advance()
    }

    private func advance() {
        index += 1
        if index >= total {
            finished = true
        } else {
            isRevealed = false
            selectedOption = nil
            typedAnswer = ""
            typedJudged = false
            typedWasCorrect = false
            prepareCurrent()
        }
    }

    private func prepareCurrent() {
        guard let card = currentCard else { return }
        if mode == .multipleChoice {
            options = StudyQueue.multipleChoiceOptions(for: card, pool: distractorPool)
        } else {
            options = []
        }
    }

    /// Interval preview string for a grade (e.g. "6d"), shown on grade buttons.
    func intervalLabel(for grade: Grade) -> String {
        guard let card = currentCard else { return "" }
        guard mode.affectsSchedule else { return "" }
        return SRSEngine.intervalPreview(card: card, grade: grade)
    }
}
