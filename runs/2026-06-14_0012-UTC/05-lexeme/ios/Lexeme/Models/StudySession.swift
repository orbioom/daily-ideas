import Foundation
import SwiftData

/// A completed study/quiz session, used for streaks, history and charts.
@Model
final class StudySession {
    var id: UUID = UUID()
    var date: Date = Date()
    /// Raw value of `QuizMode` ("mixed" for a full review).
    var modeRaw: String = "mixed"
    var total: Int = 0
    var correct: Int = 0
    var durationSec: Double = 0

    init(id: UUID = UUID(),
         date: Date = Date(),
         modeRaw: String = "mixed",
         total: Int = 0,
         correct: Int = 0,
         durationSec: Double = 0) {
        self.id = id
        self.date = date
        self.modeRaw = modeRaw
        self.total = total
        self.correct = correct
        self.durationSec = durationSec
    }

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}
