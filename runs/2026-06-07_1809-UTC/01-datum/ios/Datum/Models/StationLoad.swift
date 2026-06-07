import Foundation
import SwiftData

/// A single weighted load on a flight (a station's entered weight at its arm).
@Model
final class StationLoad {
    var id: UUID = UUID()
    var stationName: String = ""
    var arm: Double = 0
    var weight: Double = 0
    var order: Int = 0
    var flight: Flight?

    init(
        id: UUID = UUID(),
        stationName: String = "",
        arm: Double = 0,
        weight: Double = 0,
        order: Int = 0,
        flight: Flight? = nil
    ) {
        self.id = id
        self.stationName = stationName
        self.arm = arm
        self.weight = weight
        self.order = order
        self.flight = flight
    }

    /// Moment contribution of this load (weight × arm).
    var moment: Double { weight * arm }
}
