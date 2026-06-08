import Foundation
import SwiftData

@Model
final class Lodging {
    var id: UUID
    var name: String
    var address: String
    var checkIn: Date
    var checkOut: Date
    var cost: Double
    var confirmation: String
    var notes: String
    var trip: Trip?

    init(
        id: UUID = UUID(),
        name: String,
        address: String = "",
        checkIn: Date,
        checkOut: Date,
        cost: Double = 0,
        confirmation: String = "",
        notes: String = "",
        trip: Trip? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.checkIn = checkIn
        self.checkOut = checkOut
        self.cost = cost
        self.confirmation = confirmation
        self.notes = notes
        self.trip = trip
    }

    /// Number of nights this lodging covers (at least 1, crash-safe).
    func nights(_ calendar: Calendar = .current) -> Int {
        let a = calendar.startOfDay(for: checkIn)
        let b = calendar.startOfDay(for: checkOut)
        let n = calendar.dateComponents([.day], from: a, to: b).day ?? 0
        return max(1, n)
    }
}
