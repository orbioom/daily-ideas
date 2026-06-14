import Foundation
import SwiftData

/// Per-word spaced-repetition progress for the current user. One row per studied word.
@Model
final class WordProgress {
    /// Matches `VocabWord.id` (lowercased word). Unique per row by convention.
    var wordID: String = ""
    /// Mastery level 0...5 (see `LexemeEngine.intervals`).
    var level: Int = 0
    /// When this word next becomes due for review.
    var nextReview: Date = Date.distantPast
    /// How many times it has been quizzed.
    var seen: Int = 0
    /// How many times it was answered correctly.
    var correct: Int = 0
    var favorite: Bool = false
    /// User has marked it "I knew it" or reached mastery.
    var learned: Bool = false
    var lastSeen: Date?

    init(wordID: String,
         level: Int = 0,
         nextReview: Date = .distantPast,
         seen: Int = 0,
         correct: Int = 0,
         favorite: Bool = false,
         learned: Bool = false,
         lastSeen: Date? = nil) {
        self.wordID = wordID
        self.level = level
        self.nextReview = nextReview
        self.seen = seen
        self.correct = correct
        self.favorite = favorite
        self.learned = learned
        self.lastSeen = lastSeen
    }

    var accuracy: Double {
        guard seen > 0 else { return 0 }
        return Double(correct) / Double(seen)
    }
}
