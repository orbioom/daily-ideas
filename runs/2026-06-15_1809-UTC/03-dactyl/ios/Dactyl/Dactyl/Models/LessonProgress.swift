import Foundation
import SwiftData

/// Persisted per-lesson personal bests.
@Model
final class LessonProgress {
    @Attribute(.unique) var lessonID: String
    var bestWPM: Double
    var bestAccuracy: Double     // 0...1
    var completed: Bool
    var attempts: Int
    var lastPracticed: Date?

    init(lessonID: String,
         bestWPM: Double = 0,
         bestAccuracy: Double = 0,
         completed: Bool = false,
         attempts: Int = 0,
         lastPracticed: Date? = nil) {
        self.lessonID = lessonID
        self.bestWPM = bestWPM
        self.bestAccuracy = bestAccuracy
        self.completed = completed
        self.attempts = attempts
        self.lastPracticed = lastPracticed
    }
}
