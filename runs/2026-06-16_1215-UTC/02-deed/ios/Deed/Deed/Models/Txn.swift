import SwiftUI
import SwiftData

@Model
final class Txn {
    @Attribute(.unique) var id: UUID
    var date: Date
    var kindRaw: String
    var categoryRaw: String
    var amount: Decimal
    var notes: String
    /// Optional reference to a unit within the property.
    var unitID: UUID?

    var property: Property?

    init(
        id: UUID = UUID(),
        date: Date,
        kind: TxnKind,
        category: TxnCategory,
        amount: Decimal,
        notes: String = "",
        unitID: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.kindRaw = kind.rawValue
        self.categoryRaw = category.rawValue
        self.amount = amount
        self.notes = notes
        self.unitID = unitID
    }

    var kind: TxnKind {
        get { TxnKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    var category: TxnCategory {
        get { TxnCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Signed amount: income positive, expense negative.
    var signedAmount: Decimal {
        kind == .income ? amount : -amount
    }
}
