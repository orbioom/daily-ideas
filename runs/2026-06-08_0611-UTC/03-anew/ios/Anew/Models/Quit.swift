import Foundation
import SwiftData

@Model
final class Quit {
    var id: UUID
    var name: String
    var symbol: String
    var colorHex: UInt32
    var category: QuitCategory
    var startDate: Date
    var costPerUnit: Double
    var unitsPerDay: Double
    var unitLabel: String
    var motivation: String
    var createdAt: Date
    var order: Int
    var active: Bool

    @Relationship(deleteRule: .cascade)
    var relapses: [Relapse]

    @Relationship(deleteRule: .cascade)
    var checkIns: [CheckIn]

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorHex: UInt32,
        category: QuitCategory,
        startDate: Date,
        costPerUnit: Double,
        unitsPerDay: Double,
        unitLabel: String,
        motivation: String,
        createdAt: Date = Date(),
        order: Int = 0,
        active: Bool = true
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.category = category
        self.startDate = startDate
        self.costPerUnit = costPerUnit
        self.unitsPerDay = unitsPerDay
        self.unitLabel = unitLabel
        self.motivation = motivation
        self.createdAt = createdAt
        self.order = order
        self.active = active
        self.relapses = []
        self.checkIns = []
    }
}
