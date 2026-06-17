import Foundation
import SwiftData

/// A saved spread reading in the journal. Cascades its drawn cards.
@Model
final class Reading {
    @Attribute(.unique) var id: UUID
    var date: Date
    var spreadTypeRaw: String
    var question: String?
    var reflection: String
    /// Optional mood 1...5 captured with the reading.
    var mood: Int?

    @Relationship(deleteRule: .cascade, inverse: \DrawnCard.reading)
    var cards: [DrawnCard]

    init(id: UUID = UUID(),
         date: Date = .now,
         spreadType: SpreadType,
         question: String? = nil,
         reflection: String = "",
         mood: Int? = nil,
         cards: [DrawnCard] = []) {
        self.id = id
        self.date = date
        self.spreadTypeRaw = spreadType.rawValue
        self.question = question
        self.reflection = reflection
        self.mood = mood
        self.cards = cards
    }

    var spreadType: SpreadType {
        SpreadType(rawValue: spreadTypeRaw) ?? .threeCard
    }
}

/// One card within a saved reading, with its position and orientation.
@Model
final class DrawnCard {
    var cardId: Int
    var positionIndex: Int
    var reversed: Bool
    var reading: Reading?

    init(cardId: Int, positionIndex: Int, reversed: Bool, reading: Reading? = nil) {
        self.cardId = cardId
        self.positionIndex = positionIndex
        self.reversed = reversed
        self.reading = reading
    }

    /// Safe card lookup — never traps if data is somehow inconsistent.
    var card: TarotCard? { Deck.card(id: cardId) }
}

/// The history of daily draws — one per calendar day. `dayKey` is the deduplication key.
@Model
final class DailyDraw {
    @Attribute(.unique) var dayKey: String
    var date: Date
    var cardId: Int
    var reversed: Bool
    var reflection: String

    init(dayKey: String, date: Date, cardId: Int, reversed: Bool, reflection: String = "") {
        self.dayKey = dayKey
        self.date = date
        self.cardId = cardId
        self.reversed = reversed
        self.reflection = reflection
    }

    var card: TarotCard? { Deck.card(id: cardId) }
}
