import Foundation
import SwiftData

/// Money assigned to a category for a specific month ("yyyy-MM").
@Model
final class Allocation {
    @Attribute(.unique) var id: UUID
    var monthKey: String
    var amount: Double
    var category: Category?

    init(id: UUID = UUID(),
         monthKey: String,
         amount: Double,
         category: Category? = nil) {
        self.id = id
        self.monthKey = monthKey
        self.amount = amount
        self.category = category
    }
}
