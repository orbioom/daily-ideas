import Foundation
import SwiftData

/// Per verb×tense learner progress. Persisted in SwiftData.
@Model
final class ItemStat {
    @Attribute(.unique) var id: String   // "<lang>-<verb>-<tense>"
    var verbInfinitive: String
    var language: String                 // Language.rawValue
    var tense: String                    // Tense.rawValue
    var correct: Int
    var attempts: Int
    var lastSeen: Date?
    var mastery: Double                  // 0...1

    init(verbInfinitive: String,
         language: String,
         tense: String,
         correct: Int = 0,
         attempts: Int = 0,
         lastSeen: Date? = nil,
         mastery: Double = 0) {
        self.id = "\(language)-\(verbInfinitive)-\(tense)"
        self.verbInfinitive = verbInfinitive
        self.language = language
        self.tense = tense
        self.correct = correct
        self.attempts = attempts
        self.lastSeen = lastSeen
        self.mastery = mastery
    }

    /// Stable key for a verb×tense pair.
    static func makeID(language: String, verb: String, tense: String) -> String {
        "\(language)-\(verb)-\(tense)"
    }

    var languageEnum: Language? { Language(rawValue: language) }
    var tenseEnum: Tense? { Tense(rawValue: tense) }

    var accuracy: Double {
        attempts > 0 ? Double(correct) / Double(attempts) : 0
    }

    var isMastered: Bool { mastery >= 0.8 }
}
