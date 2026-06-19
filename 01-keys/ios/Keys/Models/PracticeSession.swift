import Foundation
import SwiftData

@Model
final class PracticeSession {
    var date: Date
    var moduleTitle: String
    var lessonTitle: String
    var score: Int // 0-100
    var durationSeconds: Int

    init(
        date: Date = .now,
        moduleTitle: String,
        lessonTitle: String,
        score: Int,
        durationSeconds: Int
    ) {
        self.date = date
        self.moduleTitle = moduleTitle
        self.lessonTitle = lessonTitle
        self.score = score
        self.durationSeconds = durationSeconds
    }
}
