import Foundation
import SwiftData

/// A gift-giving occasion — a birthday, holiday, anniversary, etc. Annual ones
/// roll their month/day forward each year (handled in `GiftEngine`). Gifts are
/// nullified (not deleted) when an occasion is removed.
@Model
final class Occasion {
    var name: String
    var date: Date
    var isAnnual: Bool
    var notes: String
    var budget: Double          // 0 = no budget set
    var createdAt: Date
    var sortIndex: Int

    @Relationship(deleteRule: .nullify, inverse: \Gift.occasion)
    var gifts: [Gift] = []

    init(name: String,
         date: Date,
         isAnnual: Bool = true,
         notes: String = "",
         budget: Double = 0,
         sortIndex: Int = 0) {
        self.name = name
        self.date = date
        self.isAnnual = isAnnual
        self.notes = notes
        self.budget = max(0, budget)
        self.sortIndex = sortIndex
        self.createdAt = .now
    }
}
