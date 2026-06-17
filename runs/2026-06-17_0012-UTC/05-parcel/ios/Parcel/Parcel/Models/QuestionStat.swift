import Foundation
import SwiftData

/// Per-question study statistics. One row per question the user has interacted with.
@Model
final class QuestionStat {
    /// The `Question.id` this row tracks. Unique per row.
    @Attribute(.unique) var questionId: Int
    var seen: Int
    var correct: Int
    var wrong: Int
    var flagged: Bool
    var lastSeen: Date?

    init(questionId: Int,
         seen: Int = 0,
         correct: Int = 0,
         wrong: Int = 0,
         flagged: Bool = false,
         lastSeen: Date? = nil) {
        self.questionId = questionId
        self.seen = seen
        self.correct = correct
        self.wrong = wrong
        self.flagged = flagged
        self.lastSeen = lastSeen
    }

    /// Raw accuracy in 0...1. Returns 0 when never seen (guards division).
    var accuracy: Double {
        guard seen > 0 else { return 0 }
        return Double(correct) / Double(seen)
    }

    /// Mastery in 0...1, blending accuracy with a recency bonus so that
    /// recently-correct questions count for more. Decays over ~30 days.
    var mastery: Double {
        guard seen > 0 else { return 0 }
        let base = accuracy
        guard let last = lastSeen else { return base * 0.8 }
        let days = Date().timeIntervalSince(last) / 86_400
        let recency = max(0.0, 1.0 - days / 30.0) // 1 today -> 0 after 30 days
        return min(1.0, base * 0.75 + base * recency * 0.25)
    }

    /// A small bucketed mastery level for dot indicators (0 = none ... 3 = strong).
    var masteryLevel: Int {
        if seen == 0 { return 0 }
        switch mastery {
        case ..<0.34: return 1
        case ..<0.67: return 2
        default: return 3
        }
    }
}
