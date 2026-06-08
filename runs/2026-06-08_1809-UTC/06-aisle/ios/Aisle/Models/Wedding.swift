import Foundation
import SwiftData

/// The single wedding anchor record.
@Model
final class Wedding {
    var coupleNames: String
    var weddingDate: Date
    var venue: String
    var totalBudget: Double
    var currencyCode: String
    var createdAt: Date

    init(coupleNames: String,
         weddingDate: Date,
         venue: String = "",
         totalBudget: Double = 0,
         currencyCode: String = Locale.current.currency?.identifier ?? "USD") {
        self.coupleNames = coupleNames
        self.weddingDate = weddingDate
        self.venue = venue
        self.totalBudget = max(0, totalBudget)
        self.currencyCode = currencyCode
        self.createdAt = .now
    }
}
