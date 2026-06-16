import Foundation
import SwiftData

/// A reusable, colored tag that can be applied to many cards (many-to-many).
@Model
final class Label {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: Int

    var cards: [Card]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: Int,
        cards: [Card] = []
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.cards = cards
    }
}
