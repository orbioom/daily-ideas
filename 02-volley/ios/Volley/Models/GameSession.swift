import Foundation
import SwiftData

@Model
final class GameSession {
    var date: Date
    var mode: String
    var category: String
    var questionsAnswered: Int
    var questionsSkipped: Int

    init(
        date: Date = .now,
        mode: String,
        category: String,
        questionsAnswered: Int = 0,
        questionsSkipped: Int = 0
    ) {
        self.date = date
        self.mode = mode
        self.category = category
        self.questionsAnswered = questionsAnswered
        self.questionsSkipped = questionsSkipped
    }

    var totalQuestions: Int { questionsAnswered + questionsSkipped }
}
