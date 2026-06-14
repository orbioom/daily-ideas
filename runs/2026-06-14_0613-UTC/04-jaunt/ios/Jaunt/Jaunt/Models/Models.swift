import Foundation
import SwiftData

// MARK: - Trip

@Model
final class Trip {
    @Attribute(.unique) var id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var budgetAmount: Double
    var currencyCode: String
    /// Deterministic hue (0...1) used for the cover gradient.
    var coverHue: Double
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TripDay.trip)
    var days: [TripDay]

    @Relationship(deleteRule: .cascade, inverse: \PackItem.trip)
    var packItems: [PackItem]

    @Relationship(deleteRule: .cascade, inverse: \Expense.trip)
    var expenses: [Expense]

    init(id: UUID = UUID(),
         name: String,
         destination: String,
         startDate: Date,
         endDate: Date,
         notes: String = "",
         budgetAmount: Double = 0,
         currencyCode: String = "USD",
         coverHue: Double = 0.55,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.budgetAmount = budgetAmount
        self.currencyCode = currencyCode
        self.coverHue = coverHue
        self.createdAt = createdAt
        self.days = []
        self.packItems = []
        self.expenses = []
    }
}

// MARK: - TripDay

@Model
final class TripDay {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var trip: Trip?

    @Relationship(deleteRule: .cascade, inverse: \ItineraryItem.day)
    var items: [ItineraryItem]

    init(id: UUID = UUID(),
         date: Date,
         title: String = "") {
        self.id = id
        self.date = date
        self.title = title
        self.items = []
    }
}

// MARK: - ItineraryItem

@Model
final class ItineraryItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryRaw: String
    /// Minutes from midnight, or -1 for "anytime".
    var startTimeMinutes: Int
    var durationMin: Int
    var address: String
    var notes: String
    var cost: Double
    var booked: Bool
    var sortOrder: Int
    var day: TripDay?

    init(id: UUID = UUID(),
         title: String,
         category: ItemCategory = .other,
         startTimeMinutes: Int = -1,
         durationMin: Int = 60,
         address: String = "",
         notes: String = "",
         cost: Double = 0,
         booked: Bool = false,
         sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.startTimeMinutes = startTimeMinutes
        self.durationMin = durationMin
        self.address = address
        self.notes = notes
        self.cost = cost
        self.booked = booked
        self.sortOrder = sortOrder
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var isTimed: Bool { startTimeMinutes >= 0 }
}

// MARK: - PackItem

@Model
final class PackItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var packed: Bool
    var quantity: Int
    var trip: Trip?

    init(id: UUID = UUID(),
         name: String,
         category: PackCategory = .other,
         packed: Bool = false,
         quantity: Int = 1) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.packed = packed
        self.quantity = quantity
    }

    var category: PackCategory {
        get { PackCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

// MARK: - Expense

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryRaw: String
    var amount: Double
    var date: Date
    var trip: Trip?

    init(id: UUID = UUID(),
         title: String,
         category: ItemCategory = .other,
         amount: Double = 0,
         date: Date = Date()) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.amount = amount
        self.date = date
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
