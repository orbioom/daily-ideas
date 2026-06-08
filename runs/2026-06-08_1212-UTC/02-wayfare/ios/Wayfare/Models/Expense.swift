import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var title: String
    var amount: Double
    var categoryRaw: String
    var date: Date
    var trip: Trip?

    var category: ActivityCategory {
        get { ActivityCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ActivityCategory = .other,
        date: Date = .now,
        trip: Trip? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = max(0, amount)
        self.categoryRaw = category.rawValue
        self.date = date
        self.trip = trip
    }
}
