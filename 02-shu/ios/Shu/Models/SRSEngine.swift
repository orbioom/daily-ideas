import Foundation
import Observation
import SwiftData

// MARK: - SRSEngine
/// Implements the SM-2 spaced-repetition algorithm.
/// Uses @Observable so SwiftUI views re-render reactively.
@Observable
final class SRSEngine {

    // MARK: - SM-2 Core
    /// Process a rating (0-5) for a card and update its SRS state.
    /// - rating 0-2 = fail (reset streak), 3-5 = pass (advance)
    func processRating(_ rating: Int, for review: CardReview) {
        let clampedRating = max(0, min(5, rating))

        if clampedRating < 3 {
            // Failed: reset streak, review again in 1 day
            review.repetitions = 0
            review.interval = 1
        } else {
            // Passed: advance the schedule
            switch review.repetitions {
            case 0:
                review.interval = 1
            case 1:
                review.interval = 6
            default:
                let newInterval = Double(review.interval) * review.easeFactor
                review.interval = max(1, Int(newInterval.rounded()))
            }
            review.repetitions += 1
        }

        // Update ease factor (SM-2 formula, clamped to [1.3, ∞))
        let delta = 0.1 - Double(5 - clampedRating) * (0.08 + Double(5 - clampedRating) * 0.02)
        review.easeFactor = max(1.3, review.easeFactor + delta)

        // Schedule next due date
        review.dueDate = Calendar.current.date(
            byAdding: .day,
            value: review.interval,
            to: .now
        ) ?? .now

        review.lastRating = clampedRating
    }

    // MARK: - Queries

    /// All cards that are due for review now (dueDate <= current time).
    func dueCards(from reviews: [CardReview]) -> [CardReview] {
        let now = Date.now
        return reviews
            .filter { $0.dueDate <= now }
            .sorted { $0.dueDate < $1.dueDate }
    }

    /// Mastery level for a card, expressed as a value 0.0 – 1.0.
    /// Based on the ease factor and repetition count.
    func masteryLevel(for review: CardReview) -> Double {
        guard review.repetitions > 0 else { return 0.0 }
        // Ease factor range: 1.3 (min) to ~3.5 (well-known)
        // Combine reps and ease factor into a 0-1 scale
        let efScore = min((review.easeFactor - 1.3) / 2.2, 1.0)
        let repScore = min(Double(review.repetitions) / 10.0, 1.0)
        return (efScore * 0.6 + repScore * 0.4)
    }

    // MARK: - Bootstrap
    /// Ensure every HSK word has a CardReview record in the store.
    /// Call once on app launch inside a ModelContext.
    func bootstrapReviews(context: ModelContext) {
        let existingIds: Set<Int> = {
            let descriptor = FetchDescriptor<CardReview>()
            let all = (try? context.fetch(descriptor)) ?? []
            return Set(all.map { $0.wordId })
        }()

        for word in hskWords where !existingIds.contains(word.id) {
            let review = CardReview(wordId: word.id)
            context.insert(review)
        }

        try? context.save()
    }
}
