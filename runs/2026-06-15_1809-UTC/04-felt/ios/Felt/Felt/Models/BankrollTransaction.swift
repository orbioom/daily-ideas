import Foundation
import SwiftData

/// A deposit into or withdrawal from the player's poker bankroll. Money is stored as `Decimal`.
@Model
final class BankrollTransaction {
    @Attribute(.unique) var id: UUID
    var date: Date
    var amount: Decimal
    var kindRaw: String
    var note: String

    init(id: UUID = UUID(),
         date: Date = .now,
         amount: Decimal = 0,
         kind: TransactionKind = .deposit,
         note: String = "") {
        self.id = id
        self.date = date
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.note = note
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .deposit }
        set { kindRaw = newValue.rawValue }
    }

    /// Signed effect on bankroll: deposits add, withdrawals subtract.
    var signedAmount: Decimal {
        kind == .deposit ? amount : -amount
    }
}
