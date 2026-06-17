import Foundation
import SwiftData

/// A completed drill session. Persisted in SwiftData.
@Model
final class DrillSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var language: String     // Language.rawValue
    var mode: String         // AnswerMode.rawValue ("type" / "choice")
    var total: Int
    var correct: Int
    var durationSeconds: Int

    init(date: Date = .now,
         language: String,
         mode: String,
         total: Int,
         correct: Int,
         durationSeconds: Int) {
        self.id = UUID()
        self.date = date
        self.language = language
        self.mode = mode
        self.total = total
        self.correct = correct
        self.durationSeconds = durationSeconds
    }

    var accuracy: Double {
        total > 0 ? Double(correct) / Double(total) : 0
    }

    var languageEnum: Language? { Language(rawValue: language) }
}
