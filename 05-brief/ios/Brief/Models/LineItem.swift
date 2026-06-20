import Foundation
import SwiftData

@Model
final class LineItem {
    var id: UUID
    var order: Int
    var itemDescription: String
    var quantity: Decimal
    var unitPrice: Decimal
    var invoice: Invoice?

    init(order: Int = 0, description: String = "", quantity: Decimal = 1, unitPrice: Decimal = 0) {
        self.id = UUID()
        self.order = order
        self.itemDescription = description
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    var subtotal: Decimal { quantity * unitPrice }
}
