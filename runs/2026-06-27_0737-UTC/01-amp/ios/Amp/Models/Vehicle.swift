import SwiftData
import Foundation

@Model
final class Vehicle {
    var id: UUID
    var name: String
    var make: String
    var model: String
    var year: Int
    var batteryKWh: Double
    var rangeKm: Double
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ChargingSession.vehicle)
    var sessions: [ChargingSession] = []

    init(
        name: String,
        make: String,
        model: String,
        year: Int,
        batteryKWh: Double,
        rangeKm: Double,
        colorHex: String = "#3A86FF"
    ) {
        self.id = UUID()
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.batteryKWh = batteryKWh
        self.rangeKm = rangeKm
        self.colorHex = colorHex
        self.createdAt = Date()
    }

    var displayName: String { name.isEmpty ? "\(year) \(make) \(model)" : name }

    var totalKWh: Double { sessions.reduce(0) { $0 + $1.kwhAdded } }
    var totalCost: Double { sessions.reduce(0) { $0 + $1.cost } }
    var sessionCount: Int { sessions.count }
}
