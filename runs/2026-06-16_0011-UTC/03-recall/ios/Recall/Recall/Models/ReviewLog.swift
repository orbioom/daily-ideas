import Foundation
import SwiftData

/// One graded review event. A cascade child of Deck so logs vanish with their deck.
@Model
final class ReviewLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    /// Stored as raw string; access via `grade`.
    var gradeRaw: String
    /// Snapshot of the card's front, kept legible even if the card is later deleted.
    var cardFront: String

    var deck: Deck?

    init(date: Date = .now, grade: Grade, cardFront: String) {
        self.id = UUID()
        self.date = date
        self.gradeRaw = grade.rawValue
        self.cardFront = cardFront
    }

    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .good }
        set { gradeRaw = newValue.rawValue }
    }
}
