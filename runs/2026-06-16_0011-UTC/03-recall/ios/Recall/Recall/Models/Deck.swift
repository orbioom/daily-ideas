import Foundation
import SwiftData

@Model
final class Deck {
    @Attribute(.unique) var id: UUID
    var name: String
    var deckDescription: String
    var colorSeed: Int
    var category: String
    var createdDate: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.deck)
    var logs: [ReviewLog] = []

    init(name: String,
         deckDescription: String = "",
         colorSeed: Int = 0,
         category: String = "General",
         createdDate: Date = .now,
         isArchived: Bool = false) {
        self.id = UUID()
        self.name = name
        self.deckDescription = deckDescription
        self.colorSeed = colorSeed
        self.category = category
        self.createdDate = createdDate
        self.isArchived = isArchived
        self.cards = []
        self.logs = []
    }

    /// Cards that are not suspended.
    var activeCards: [Card] {
        cards.filter { !$0.isSuspended }
    }
}
