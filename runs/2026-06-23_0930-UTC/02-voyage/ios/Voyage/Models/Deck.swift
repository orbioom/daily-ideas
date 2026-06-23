import Foundation
import SwiftData

/// A language deck — a curated collection of travel phrases for one language.
@Model
final class Deck {
    /// Stable unique identity.
    @Attribute(.unique) var id: UUID
    /// Display name, e.g. "Spanish".
    var name: String
    /// Native endonym, e.g. "Español".
    var endonym: String
    /// Flag emoji used as the deck glyph.
    var flag: String
    /// BCP-47 voice locale for AVSpeechSynthesizer, e.g. "es-ES".
    var localeIdentifier: String
    /// Short tagline shown on the deck card.
    var subtitle: String
    /// Sort order for stable display.
    var sortIndex: Int
    /// Creation timestamp (used for tie-break sorting & "added" info).
    var createdAt: Date

    /// Phrases belonging to this deck. Deleting a deck cascades to its phrases.
    @Relationship(deleteRule: .cascade, inverse: \Phrase.deck)
    var phrases: [Phrase]

    init(
        id: UUID = UUID(),
        name: String,
        endonym: String,
        flag: String,
        localeIdentifier: String,
        subtitle: String,
        sortIndex: Int = 0,
        createdAt: Date = .now,
        phrases: [Phrase] = []
    ) {
        self.id = id
        self.name = name
        self.endonym = endonym
        self.flag = flag
        self.localeIdentifier = localeIdentifier
        self.subtitle = subtitle
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.phrases = phrases
    }
}
