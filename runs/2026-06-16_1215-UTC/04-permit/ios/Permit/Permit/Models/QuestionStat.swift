import Foundation
import SwiftData

/// Per-question learning record. One row per question the learner has interacted with.
@Model
final class QuestionStat {
    @Attribute(.unique) var questionID: Int
    var timesSeen: Int
    var timesCorrect: Int
    var lastSeen: Date?
    var correctStreak: Int
    var isFlagged: Bool

    init(
        questionID: Int,
        timesSeen: Int = 0,
        timesCorrect: Int = 0,
        lastSeen: Date? = nil,
        correctStreak: Int = 0,
        isFlagged: Bool = false
    ) {
        self.questionID = questionID
        self.timesSeen = timesSeen
        self.timesCorrect = timesCorrect
        self.lastSeen = lastSeen
        self.correctStreak = correctStreak
        self.isFlagged = isFlagged
    }

    /// Considered mastered once answered correctly 3 times in a row.
    var isMastered: Bool { correctStreak >= 3 }

    var accuracy: Double {
        guard timesSeen > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesSeen)
    }

    func record(correct: Bool, date: Date = .now) {
        timesSeen += 1
        lastSeen = date
        if correct {
            timesCorrect += 1
            correctStreak += 1
        } else {
            correctStreak = 0
        }
    }
}
