import Foundation
import SwiftData
import SwiftUI

/// Drives a single review session for a deck: assembles the due/new queue,
/// tracks the current card, applies SM-2 grades and records session results.
@MainActor
@Observable
final class ReviewSessionViewModel {

    enum Phase {
        case loading
        case studying
        case finished
        case empty
    }

    private(set) var phase: Phase = .loading
    private(set) var queue: [Phrase] = []
    private(set) var index: Int = 0
    private(set) var isRevealed = false

    /// Counters for the summary screen.
    private(set) var gradedCount = 0
    private(set) var againCount = 0
    private(set) var goodCount = 0

    let deck: Deck
    private let context: ModelContext
    private let newLimit: Int

    init(deck: Deck, context: ModelContext, newLimit: Int) {
        self.deck = deck
        self.context = context
        self.newLimit = max(0, newLimit)
    }

    var currentPhrase: Phrase? {
        guard index >= 0, index < queue.count else { return nil }
        return queue[index]
    }

    var progressText: String {
        guard !queue.isEmpty else { return "" }
        return "\(min(index + 1, queue.count)) / \(queue.count)"
    }

    var progressFraction: Double {
        guard !queue.isEmpty else { return 0 }
        return Double(index) / Double(queue.count)
    }

    /// Build the study queue: all due review cards first, then up to `newLimit`
    /// new cards. Simulates a brief load for a calm loading state.
    func start() async {
        phase = .loading
        // Yield so the loading state can render at least one frame.
        try? await Task.sleep(nanoseconds: 350_000_000)

        let now = Date()
        let phrases = deck.phrases

        var due: [Phrase] = []
        var fresh: [Phrase] = []
        for phrase in phrases {
            if let state = phrase.reviewState, state.totalReviews > 0 {
                if state.dueDate.isDue(by: now) { due.append(phrase) }
            } else {
                fresh.append(phrase)
            }
        }
        // Stable, deterministic ordering: due by soonest, new by deck order.
        due.sort { ($0.reviewState?.dueDate ?? now) < ($1.reviewState?.dueDate ?? now) }
        fresh.sort { $0.orderIndex < $1.orderIndex }

        let chosenNew = Array(fresh.prefix(newLimit))
        queue = due + chosenNew
        index = 0
        isRevealed = false
        gradedCount = 0
        againCount = 0
        goodCount = 0

        phase = queue.isEmpty ? .empty : .studying
    }

    func reveal() {
        isRevealed = true
    }

    /// Apply a self-grade to the current card, schedule it, and advance.
    func grade(_ grade: ReviewGrade) {
        guard let phrase = currentPhrase else { return }

        let state = phrase.reviewState ?? {
            let s = ReviewState(phrase: phrase)
            phrase.reviewState = s
            context.insert(s)
            return s
        }()

        let outcome = SRSEngine.schedule(
            grade: grade,
            easeFactor: state.easeFactor,
            intervalDays: state.intervalDays,
            repetitions: state.repetitions,
            lapses: state.lapses
        )
        state.easeFactor = outcome.easeFactor
        state.intervalDays = outcome.intervalDays
        state.repetitions = outcome.repetitions
        state.lapses = outcome.lapses
        state.dueDate = outcome.dueDate
        state.lastReviewed = Date()
        state.totalReviews += 1

        try? context.save()

        gradedCount += 1
        if grade == .again { againCount += 1 } else { goodCount += 1 }

        advance(afterAgain: grade == .again, phrase: phrase)
    }

    /// Move to the next card. If graded "Again", re-queue the card later so it
    /// is seen again before the session ends.
    private func advance(afterAgain: Bool, phrase: Phrase) {
        if afterAgain {
            // Re-insert a few positions ahead (or at the end) for re-study.
            let insertAt = min(queue.count, index + 4)
            queue.insert(phrase, at: insertAt)
        }
        index += 1
        isRevealed = false
        if index >= queue.count {
            phase = .finished
        }
    }

    /// Time-to-next-review preview for a hypothetical grade on the current card.
    func intervalPreview(for grade: ReviewGrade) -> String {
        guard let phrase = currentPhrase else { return "" }
        let state = phrase.reviewState
        let outcome = SRSEngine.schedule(
            grade: grade,
            easeFactor: state?.easeFactor ?? 2.5,
            intervalDays: state?.intervalDays ?? 0,
            repetitions: state?.repetitions ?? 0,
            lapses: state?.lapses ?? 0
        )
        if outcome.intervalDays <= 1 { return "1d" }
        if outcome.intervalDays < 30 { return "\(outcome.intervalDays)d" }
        let months = outcome.intervalDays / 30
        return "\(months)mo"
    }
}
