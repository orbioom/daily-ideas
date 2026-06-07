import Foundation
import SwiftData

/// A loading station on an aircraft (front seats, baggage, etc.) defined by its
/// arm and an optional per-station maximum weight.
@Model
final class Station {
    var id: UUID = UUID()
    var name: String = ""
    var arm: Double = 0           // inches aft of datum
    var maxWeight: Double = 0     // 0 = no station limit
    var defaultWeight: Double = 0 // prefilled value for new flights
    var order: Int = 0
    var aircraft: Aircraft?

    init(
        id: UUID = UUID(),
        name: String = "",
        arm: Double = 0,
        maxWeight: Double = 0,
        defaultWeight: Double = 0,
        order: Int = 0,
        aircraft: Aircraft? = nil
    ) {
        self.id = id
        self.name = name
        self.arm = arm
        self.maxWeight = maxWeight
        self.defaultWeight = defaultWeight
        self.order = order
        self.aircraft = aircraft
    }
}
