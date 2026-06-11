import Foundation
import SwiftData

struct SM2Engine {
    static func review(card: FlashCard, rating: ReviewRating, context: ModelContext) {
        let q = rating.rawValue

        if q < 2 {
            card.repetitions = 0
            card.intervalDays = 1
        } else {
            switch card.repetitions {
            case 0:  card.intervalDays = 1
            case 1:  card.intervalDays = 6
            default: card.intervalDays = max(1, Int(Double(card.intervalDays) * card.easeFactor))
            }
            card.repetitions += 1
        }

        let delta = 0.1 - Double(3 - q) * (0.08 + Double(3 - q) * 0.02)
        card.easeFactor = max(1.3, card.easeFactor + delta)

        card.nextReview = Calendar.current.date(
            byAdding: .day, value: card.intervalDays, to: Date()
        ) ?? Date()

        let review = CardReview(rating: q, intervalDays: card.intervalDays)
        review.card = card
        context.insert(review)
    }
}

@Observable
final class StudySession {
    private(set) var queue: [FlashCard] = []
    private(set) var currentIndex: Int = 0
    private(set) var isFlipped = false
    private(set) var reviewedCount = 0
    private(set) var againCount = 0
    private(set) var isComplete = false

    var current: FlashCard? { queue.indices.contains(currentIndex) ? queue[currentIndex] : nil }
    var progress: Double { queue.isEmpty ? 1 : Double(currentIndex) / Double(queue.count) }

    func load(cards: [FlashCard], limit: Int) {
        let due = cards.filter(\.isDue).prefix(limit)
        queue = Array(due).shuffled()
        currentIndex = 0
        isFlipped = false
        reviewedCount = 0
        againCount = 0
        isComplete = queue.isEmpty
    }

    func flip() { isFlipped = true }

    func answer(rating: ReviewRating, context: ModelContext) {
        guard let card = current else { return }
        SM2Engine.review(card: card, rating: rating, context: context)
        reviewedCount += 1
        if rating == .again { againCount += 1 }

        if currentIndex < queue.count - 1 {
            currentIndex += 1
            isFlipped = false
        } else {
            isComplete = true
        }
    }
}
