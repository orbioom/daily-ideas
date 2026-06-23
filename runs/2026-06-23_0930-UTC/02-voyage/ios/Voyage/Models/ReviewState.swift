import Foundation
import SwiftData

/// SM-2 spaced-repetition state for a single phrase.
/// Tracks ease factor, interval, repetition count and the next due date.
@Model
final class ReviewState {
    @Attribute(.unique) var id: UUID
    /// Ease factor (SM-2). Starts at 2.5, floored at 1.3.
    var easeFactor: Double
    /// Current interval in days until the next review.
    var intervalDays: Int
    /// Consecutive successful repetitions.
    var repetitions: Int
    /// Number of times the card lapsed (graded "Again").
    var lapses: Int
    /// When the card is next due.
    var dueDate: Date
    /// Last time the card was reviewed.
    var lastReviewed: Date?
    /// Total number of reviews ever performed on this card.
    var totalReviews: Int

    /// Owning phrase (inverse of `Phrase.reviewState`).
    var phrase: Phrase?

    init(
        id: UUID = UUID(),
        easeFactor: Double = 2.5,
        intervalDays: Int = 0,
        repetitions: Int = 0,
        lapses: Int = 0,
        dueDate: Date = .now,
        lastReviewed: Date? = nil,
        totalReviews: Int = 0,
        phrase: Phrase? = nil
    ) {
        self.id = id
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.repetitions = repetitions
        self.lapses = lapses
        self.dueDate = dueDate
        self.lastReviewed = lastReviewed
        self.totalReviews = totalReviews
        self.phrase = phrase
    }

    /// Maturity bucket derived from current interval.
    var maturity: Maturity {
        if totalReviews == 0 { return .new }
        if intervalDays >= 21 { return .mastered }
        return .learning
    }

    enum Maturity: String {
        case new = "New"
        case learning = "Learning"
        case mastered = "Mastered"
    }
}
