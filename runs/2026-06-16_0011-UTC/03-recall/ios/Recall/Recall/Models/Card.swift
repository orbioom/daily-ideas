import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var front: String
    var back: String
    var hint: String
    var example: String
    var createdDate: Date

    // MARK: SRS state (driven by SRSEngine)
    var ease: Double
    var intervalDays: Int
    var repetitions: Int
    var dueDate: Date
    var lastReviewed: Date?
    var lapses: Int
    var isSuspended: Bool

    var deck: Deck?

    init(front: String,
         back: String,
         hint: String = "",
         example: String = "",
         createdDate: Date = .now,
         ease: Double = 2.5,
         intervalDays: Int = 0,
         repetitions: Int = 0,
         dueDate: Date = .now,
         lastReviewed: Date? = nil,
         lapses: Int = 0,
         isSuspended: Bool = false) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.hint = hint
        self.example = example
        self.createdDate = createdDate
        self.ease = ease
        self.intervalDays = intervalDays
        self.repetitions = repetitions
        self.dueDate = dueDate
        self.lastReviewed = lastReviewed
        self.lapses = lapses
        self.isSuspended = isSuspended
    }

    /// A card that has never been reviewed.
    var isNew: Bool {
        lastReviewed == nil && repetitions == 0
    }

    /// Maturity bucket: new / learning / young (<21d interval) / mature (>=21d interval).
    var maturity: Maturity {
        if isNew { return .new }
        if intervalDays < 1 { return .learning }
        if repetitions < 2 || intervalDays < 7 { return .learning }
        if intervalDays < 21 { return .young }
        return .mature
    }

    var hasHint: Bool { !hint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var hasExample: Bool { !example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
