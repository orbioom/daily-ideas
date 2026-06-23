import Foundation
import SwiftData

/// A single travel phrase: source (English) + target translation + pronunciation hint.
@Model
final class Phrase {
    @Attribute(.unique) var id: UUID
    /// English meaning, e.g. "Where is the train station?"
    var source: String
    /// Target-language translation, e.g. "¿Dónde está la estación de tren?"
    var target: String
    /// Phonetic / romanized pronunciation hint, e.g. "DON-deh es-TAH..."
    var pronunciation: String
    /// Raw value of `PhraseCategory`.
    var categoryRaw: String
    /// User favorite flag.
    var isFavorite: Bool
    /// Order within the deck.
    var orderIndex: Int

    /// Owning deck (inverse of `Deck.phrases`).
    var deck: Deck?

    /// The spaced-repetition state for this phrase. Created lazily on first review.
    @Relationship(deleteRule: .cascade, inverse: \ReviewState.phrase)
    var reviewState: ReviewState?

    init(
        id: UUID = UUID(),
        source: String,
        target: String,
        pronunciation: String,
        category: PhraseCategory,
        isFavorite: Bool = false,
        orderIndex: Int = 0,
        deck: Deck? = nil
    ) {
        self.id = id
        self.source = source
        self.target = target
        self.pronunciation = pronunciation
        self.categoryRaw = category.rawValue
        self.isFavorite = isFavorite
        self.orderIndex = orderIndex
        self.deck = deck
    }

    /// Typed accessor for the category, defaulting to `.basics` if data is corrupt.
    var category: PhraseCategory {
        PhraseCategory(rawValue: categoryRaw) ?? .basics
    }
}
