import Foundation
import SwiftData

/// A single money movement. Positive amount = inflow/income, negative = outflow/spending.
@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var date: Date
    var payee: String
    var amount: Double
    var note: String
    var cleared: Bool
    var categoryRef: Category?
    var accountRef: Account?

    init(id: UUID = UUID(),
         date: Date = .now,
         payee: String,
         amount: Double,
         note: String = "",
         cleared: Bool = true,
         categoryRef: Category? = nil,
         accountRef: Account? = nil) {
        self.id = id
        self.date = date
        self.payee = payee
        self.amount = amount
        self.note = note
        self.cleared = cleared
        self.categoryRef = categoryRef
        self.accountRef = accountRef
    }

    var isInflow: Bool { amount >= 0 }
}
