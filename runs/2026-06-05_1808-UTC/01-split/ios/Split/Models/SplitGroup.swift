import Foundation
import SwiftData

/// A shared-spending context: a trip, a flat, a dinner. Owns its members,
/// expenses, and recorded settlements (all cascade-deleted with the group).
@Model
final class SplitGroup {
    var id: UUID
    var name: String
    /// A single emoji/glyph shown as the group's avatar.
    var glyph: String
    /// ISO-style currency code (e.g. "USD"); symbol resolved via Currency.
    var currencyCode: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Member.group)
    var members: [Member]

    @Relationship(deleteRule: .cascade, inverse: \Expense.group)
    var expenses: [Expense]

    @Relationship(deleteRule: .cascade, inverse: \Settlement.group)
    var settlements: [Settlement]

    init(id: UUID = UUID(),
         name: String,
         glyph: String = "🧾",
         currencyCode: String = "USD",
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.glyph = glyph
        self.currencyCode = currencyCode
        self.createdAt = createdAt
        self.members = []
        self.expenses = []
        self.settlements = []
    }

    /// Resolved currency symbol for display.
    var currencySymbol: String { Currency.symbol(for: currencyCode) }

    /// Members ordered by creation for stable lists.
    var orderedMembers: [Member] {
        members.sorted { $0.createdAt < $1.createdAt }
    }

    /// Expenses newest-first.
    var orderedExpenses: [Expense] {
        expenses.sorted { $0.date > $1.date }
    }

    /// Settlements newest-first.
    var orderedSettlements: [Settlement] {
        settlements.sorted { $0.date > $1.date }
    }
}
