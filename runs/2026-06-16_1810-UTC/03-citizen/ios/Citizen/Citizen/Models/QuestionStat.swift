import Foundation
import SwiftData

/// Per-question study statistics. One row per civics question the user has interacted with.
@Model
final class QuestionStat {
    /// The official USCIS question number (1...100). Unique per row.
    @Attribute(.unique) var questionNumber: Int
    var timesSeen: Int
    var timesCorrect: Int
    var lastSeen: Date?
    var isFlagged: Bool

    init(questionNumber: Int,
         timesSeen: Int = 0,
         timesCorrect: Int = 0,
         lastSeen: Date? = nil,
         isFlagged: Bool = false) {
        self.questionNumber = questionNumber
        self.timesSeen = timesSeen
        self.timesCorrect = timesCorrect
        self.lastSeen = lastSeen
        self.isFlagged = isFlagged
    }

    /// Raw accuracy in 0...1. Returns 0 when never seen (guards division).
    var accuracy: Double {
        guard timesSeen > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesSeen)
    }

    /// Mastery in 0...1, blending accuracy with a recency bonus so that
    /// recently-correct questions count for more. Decays over ~30 days.
    var mastery: Double {
        guard timesSeen > 0 else { return 0 }
        let base = accuracy
        guard let last = lastSeen else { return base * 0.8 }
        let days = Date().timeIntervalSince(last) / 86_400
        let recency = max(0.0, 1.0 - days / 30.0) // 1 today -> 0 after 30 days
        // Weight accuracy heavily, recency lightly.
        return min(1.0, base * 0.75 + base * recency * 0.25)
    }

    /// A small bucketed mastery level for dot indicators (0 = none ... 3 = strong).
    var masteryLevel: Int {
        if timesSeen == 0 { return 0 }
        switch mastery {
        case ..<0.34: return 1
        case ..<0.67: return 2
        default: return 3
        }
    }
}
