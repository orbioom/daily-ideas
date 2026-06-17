import Foundation
import SwiftData

/// A logged price change for a subscription — powers the price-history sparkline.
@Model
final class PriceChange {
    @Attribute(.unique) var id: UUID
    var date: Date
    var oldAmount: Double
    var newAmount: Double

    /// Back-reference to the owning subscription (inverse declared on Subscription).
    var subscription: Subscription?

    init(id: UUID = UUID(),
         date: Date = Date(),
         oldAmount: Double,
         newAmount: Double,
         subscription: Subscription? = nil) {
        self.id = id
        self.date = date
        self.oldAmount = max(0, oldAmount)
        self.newAmount = max(0, newAmount)
        self.subscription = subscription
    }

    /// Signed delta (positive = price hike).
    var delta: Double { newAmount - oldAmount }
}
