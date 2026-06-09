import Foundation
import SwiftData

/// A saved tarot reading: the spread used, the user's question and reflection,
/// and the drawn cards. Cards cascade-delete with the reading.
@Model
final class Reading {
    var date: Date
    var spreadName: String
    var question: String
    var note: String
    var isFavorite: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DrawnCard.reading)
    var cards: [DrawnCard]

    init(date: Date = .now,
         spreadName: String,
         question: String = "",
         note: String = "",
         isFavorite: Bool = false,
         cards: [DrawnCard] = []) {
        self.date = date
        self.spreadName = spreadName
        self.question = question
        self.note = note
        self.isFavorite = isFavorite
        self.createdAt = .now
        self.cards = cards
    }

    /// Cards in their drawn order (positionIndex ascending).
    var orderedCards: [DrawnCard] {
        cards.sorted { $0.positionIndex < $1.positionIndex }
    }

    /// The spread definition this reading used, if it still exists in the catalog.
    var spread: Spread? { SpreadCatalog.spread(named: spreadName) }
}

/// One card placed in one position of a reading.
@Model
final class DrawnCard {
    var positionIndex: Int
    var positionTitle: String
    var cardID: Int
    var isReversed: Bool
    var note: String

    var reading: Reading?

    init(positionIndex: Int,
         positionTitle: String,
         cardID: Int,
         isReversed: Bool,
         note: String = "") {
        self.positionIndex = positionIndex
        self.positionTitle = positionTitle
        self.cardID = cardID
        self.isReversed = isReversed
        self.note = note
    }

    /// The static catalog card this drawn card refers to, if found.
    var card: TarotCard? { TarotDeck.card(id: cardID) }
}
