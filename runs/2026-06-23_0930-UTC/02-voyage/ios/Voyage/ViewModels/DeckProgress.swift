import Foundation

/// Pure value type summarising a deck's learning progress.
/// Computed from phrases + their review states; no SwiftData dependency.
struct DeckProgress {
    let total: Int
    let newCount: Int
    let learningCount: Int
    let masteredCount: Int
    let dueCount: Int

    /// Fraction mastered, 0...1, guarded against division by zero.
    var masteryFraction: Double {
        guard total > 0 else { return 0 }
        return Double(masteredCount) / Double(total)
    }

    /// Fraction that has been seen at least once (learning + mastered).
    var seenFraction: Double {
        guard total > 0 else { return 0 }
        return Double(learningCount + masteredCount) / Double(total)
    }

    static let empty = DeckProgress(total: 0, newCount: 0, learningCount: 0, masteredCount: 0, dueCount: 0)

    /// Build progress for a list of phrases as of `now`.
    static func make(phrases: [Phrase], now: Date = .now) -> DeckProgress {
        var newC = 0, learnC = 0, masterC = 0, dueC = 0
        for phrase in phrases {
            guard let state = phrase.reviewState, state.totalReviews > 0 else {
                newC += 1
                // New cards are inherently "available" to study.
                continue
            }
            switch state.maturity {
            case .new: newC += 1
            case .learning: learnC += 1
            case .mastered: masterC += 1
            }
            if state.dueDate.isDue(by: now) { dueC += 1 }
        }
        return DeckProgress(
            total: phrases.count,
            newCount: newC,
            learningCount: learnC,
            masteredCount: masterC,
            dueCount: dueC
        )
    }
}
