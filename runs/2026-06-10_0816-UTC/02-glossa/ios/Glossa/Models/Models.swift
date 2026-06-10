import Foundation
import SwiftData

@Model
final class Deck {
    var name: String
    var languageCode: String   // "es" | "fr" | "de" | "custom"
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    init(name: String, languageCode: String, createdAt: Date = .now) {
        self.name = name
        self.languageCode = languageCode
        self.createdAt = createdAt
    }

    var flag: String {
        switch languageCode {
        case "es": return "🇪🇸"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        default: return "🌐"
        }
    }

    func dueCards(now: Date = .now) -> [Card] {
        cards.filter { $0.dueDate <= now }
    }

    var masteredCount: Int { cards.filter { $0.box >= LeitnerEngine.boxCount }.count }
}

@Model
final class Card {
    var front: String          // target language, article included for nouns
    var back: String           // English
    var gender: String         // "m" | "f" | "n" | ""
    var exampleTarget: String
    var exampleEnglish: String
    var box: Int               // 1...5 Leitner box
    var dueDate: Date
    var reviews: Int
    var lapses: Int
    var lastReviewed: Date?
    var createdAt: Date
    var catalogID: String      // built-in pack id, "" for custom cards
    var deck: Deck?

    init(front: String, back: String, gender: String = "",
         exampleTarget: String = "", exampleEnglish: String = "",
         box: Int = 1, dueDate: Date = .now, catalogID: String = "",
         createdAt: Date = .now) {
        self.front = front
        self.back = back
        self.gender = gender
        self.exampleTarget = exampleTarget
        self.exampleEnglish = exampleEnglish
        self.box = box
        self.dueDate = dueDate
        self.reviews = 0
        self.lapses = 0
        self.lastReviewed = nil
        self.createdAt = createdAt
        self.catalogID = catalogID
    }

    var genderLabel: String {
        switch gender {
        case "m": return "masculine"
        case "f": return "feminine"
        case "n": return "neuter"
        default: return ""
        }
    }
}

/// One finished study session, kept for streaks and charts.
@Model
final class ReviewSession {
    var date: Date
    var deckName: String
    var correct: Int
    var missed: Int

    init(date: Date = .now, deckName: String, correct: Int, missed: Int) {
        self.date = date
        self.deckName = deckName
        self.correct = correct
        self.missed = missed
    }
}
