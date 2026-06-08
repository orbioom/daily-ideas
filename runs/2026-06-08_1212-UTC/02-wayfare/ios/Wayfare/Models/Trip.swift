import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var colorHex: UInt32
    var currencyCode: String
    var budget: Double          // 0 = no budget set
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Activity.trip)
    var activities: [Activity] = []

    @Relationship(deleteRule: .cascade, inverse: \Lodging.trip)
    var lodgings: [Lodging] = []

    @Relationship(deleteRule: .cascade, inverse: \PackingItem.trip)
    var packingItems: [PackingItem] = []

    @Relationship(deleteRule: .cascade, inverse: \Expense.trip)
    var expenses: [Expense] = []

    init(
        id: UUID = UUID(),
        name: String,
        destination: String = "",
        startDate: Date,
        endDate: Date,
        notes: String = "",
        colorHex: UInt32 = 0x3E8E9E,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        budget: Double = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.colorHex = colorHex
        self.currencyCode = currencyCode
        self.budget = budget
        self.createdAt = createdAt
    }
}

enum TripStatus {
    case upcoming(daysAway: Int)
    case active(dayNumber: Int, total: Int)
    case past

    var label: String {
        switch self {
        case .upcoming(let d):
            if d == 0 { return "Starts today" }
            return d == 1 ? "Tomorrow" : "In \(d) days"
        case .active(let n, let total):
            return "Day \(n) of \(total)"
        case .past:
            return "Completed"
        }
    }
}
