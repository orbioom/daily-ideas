import Foundation
import SwiftData

/// A logged historical dividend payment for a holding. Money values are `Decimal`.
@Model
final class DividendPayment {
    @Attribute(.unique) var id: UUID
    var exDate: Date?
    var payDate: Date
    var amountPerShare: Decimal
    var sharesAtPayment: Decimal
    /// Stored total = amountPerShare × sharesAtPayment (kept in sync at write time).
    var total: Decimal
    var reinvested: Bool

    var holding: Holding?

    init(id: UUID = UUID(),
         exDate: Date? = nil,
         payDate: Date,
         amountPerShare: Decimal,
         sharesAtPayment: Decimal,
         reinvested: Bool = false,
         holding: Holding? = nil) {
        self.id = id
        self.exDate = exDate
        self.payDate = payDate
        self.amountPerShare = amountPerShare
        self.sharesAtPayment = sharesAtPayment
        self.total = amountPerShare * sharesAtPayment
        self.reinvested = reinvested
        self.holding = holding
    }

    /// Recompute the stored total from current per-share × shares.
    func refreshTotal() {
        total = amountPerShare * sharesAtPayment
    }
}
