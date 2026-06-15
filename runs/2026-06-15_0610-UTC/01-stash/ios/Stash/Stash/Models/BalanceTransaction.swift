import Foundation
import SwiftData

/// A single spend logged against a gift card. Positive `amount` reduces the
/// remaining balance. Owned by its `GiftCard` via a cascade relationship.
@Model
final class BalanceTransaction {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var note: String
    var date: Date
    var giftCard: GiftCard?

    init(id: UUID = UUID(),
         amount: Decimal,
         note: String = "",
         date: Date = Date(),
         giftCard: GiftCard? = nil) {
        self.id = id
        self.amount = amount
        self.note = note
        self.date = date
        self.giftCard = giftCard
    }
}
