import SwiftUI
import SwiftData

@Model
final class Property {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var typeRaw: String
    var purchasePrice: Decimal
    var purchaseDate: Date
    var currentValue: Decimal
    var downPayment: Decimal
    var closingCosts: Decimal
    var mortgageBalance: Decimal
    /// Monthly principal & interest payment.
    var mortgagePayment: Decimal
    var colorHex: Int
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Unit.property)
    var units: [Unit]

    @Relationship(deleteRule: .cascade, inverse: \Txn.property)
    var transactions: [Txn]

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        type: PropertyType,
        purchasePrice: Decimal,
        purchaseDate: Date,
        currentValue: Decimal,
        downPayment: Decimal,
        closingCosts: Decimal,
        mortgageBalance: Decimal,
        mortgagePayment: Decimal,
        colorHex: Int,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.typeRaw = type.rawValue
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.currentValue = currentValue
        self.downPayment = downPayment
        self.closingCosts = closingCosts
        self.mortgageBalance = mortgageBalance
        self.mortgagePayment = mortgagePayment
        self.colorHex = colorHex
        self.notes = notes
        self.createdAt = createdAt
        self.units = []
        self.transactions = []
    }

    var type: PropertyType {
        get { PropertyType(rawValue: typeRaw) ?? .singleFamily }
        set { typeRaw = newValue.rawValue }
    }

    var identityColor: Color { Color(hex: UInt(bitPattern: colorHex) & 0xFFFFFF) }

    var identityGradient: LinearGradient {
        let base = identityColor
        return LinearGradient(
            colors: [base, base.opacity(0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
