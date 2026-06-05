import Foundation
import SwiftData

/// A single shared cost. The payer fronted `amount`; the participants owe shares
/// computed from `splitMode` and the per-participant `shares` weights/amounts.
@Model
final class Expense {
    var id: UUID
    var title: String
    /// Total amount paid. Always positive. Stored as Decimal (never Double).
    var amount: Decimal
    var date: Date
    var notes: String
    /// Raw value of SplitMode for tolerant decoding.
    var splitModeRaw: String

    var group: SplitGroup?

    /// The member who paid.
    @Relationship var payer: Member?

    /// Per-participant share rows. For .equal this still lists participants (value
    /// ignored); for .exact `value` is the entered amount; for .shares `value` is a weight.
    @Relationship(deleteRule: .cascade, inverse: \ExpenseShare.expense)
    var shares: [ExpenseShare]

    init(id: UUID = UUID(),
         title: String,
         amount: Decimal,
         date: Date = .now,
         notes: String = "",
         splitMode: SplitMode = .equal,
         payer: Member? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.notes = notes
        self.splitModeRaw = splitMode.rawValue
        self.payer = payer
        self.shares = []
    }

    /// Tolerant accessor — falls back to equal for any unknown raw value.
    var splitMode: SplitMode {
        get { SplitMode(rawValue: splitModeRaw) ?? .equal }
        set { splitModeRaw = newValue.rawValue }
    }

    /// Participants involved (members that have a share row), ordered stably.
    var participants: [Member] {
        shares.compactMap(\.member).sorted { $0.createdAt < $1.createdAt }
    }
}

/// One participant's involvement in an expense. `value` meaning depends on the
/// expense's split mode (ignored for equal, exact amount for exact, weight for shares).
@Model
final class ExpenseShare {
    var id: UUID
    /// Exact amount (exact mode) or weight (shares mode); ignored for equal.
    var value: Decimal

    var expense: Expense?
    @Relationship var member: Member?

    init(id: UUID = UUID(), value: Decimal = 0, member: Member? = nil) {
        self.id = id
        self.value = value
        self.member = member
    }
}
