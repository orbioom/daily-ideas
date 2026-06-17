import Foundation
import SwiftData

/// A recorded set within a completed session, with actual swum time.
@Model
final class CompletedSet {
    var order: Int
    var strokeRaw: String
    var repeats: Int
    var distancePerRepMeters: Double
    var actualTimeSeconds: Double     // total swimming time across all reps
    var restSeconds: Int              // rest taken after each rep
    var strokeCountPerLength: Int?    // optional, enables SWOLF

    var session: SwimSession?

    init(order: Int,
         stroke: Stroke,
         repeats: Int,
         distancePerRepMeters: Double,
         actualTimeSeconds: Double,
         restSeconds: Int = 0,
         strokeCountPerLength: Int? = nil) {
        self.order = order
        self.strokeRaw = stroke.rawValue
        self.repeats = max(1, repeats)
        self.distancePerRepMeters = max(0, distancePerRepMeters)
        self.actualTimeSeconds = max(0, actualTimeSeconds)
        self.restSeconds = max(0, restSeconds)
        self.strokeCountPerLength = strokeCountPerLength
    }

    var stroke: Stroke {
        get { Stroke.from(strokeRaw) }
        set { strokeRaw = newValue.rawValue }
    }

    var totalDistanceMeters: Double {
        Double(max(1, repeats)) * max(0, distancePerRepMeters)
    }
}
