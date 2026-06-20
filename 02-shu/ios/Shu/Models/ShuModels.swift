import Foundation
import SwiftData

// MARK: - CardReview
/// Tracks the SRS state for a single HSK word.
@Model
final class CardReview {
    var wordId: Int
    var interval: Int        // days until next review
    var easeFactor: Double   // SM-2 ease factor, starts at 2.5
    var dueDate: Date
    var repetitions: Int     // number of successful reviews in a row
    var lastRating: Int      // 0-5, most recent rating given by user

    init(wordId: Int) {
        self.wordId = wordId
        self.interval = 0
        self.easeFactor = 2.5
        self.dueDate = .now
        self.repetitions = 0
        self.lastRating = -1
    }
}

// MARK: - StudySession
/// Records a single study session for stats and streak tracking.
@Model
final class StudySession {
    var date: Date
    var cardsReviewed: Int
    var correctCount: Int

    init(date: Date = .now, cardsReviewed: Int = 0, correctCount: Int = 0) {
        self.date = date
        self.cardsReviewed = cardsReviewed
        self.correctCount = correctCount
    }

    /// Accuracy as a percentage (0-100), or 0 if no cards reviewed.
    var accuracy: Int {
        guard cardsReviewed > 0 else { return 0 }
        return Int(Double(correctCount) / Double(cardsReviewed) * 100)
    }
}
