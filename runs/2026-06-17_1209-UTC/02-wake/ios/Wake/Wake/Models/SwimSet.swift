import Foundation
import SwiftData

/// One line of a workout, e.g. "4 × 100 freestyle @ 1:45".
@Model
final class SwimSet {
    var order: Int
    var repeats: Int
    var distancePerRepMeters: Double
    var strokeRaw: String
    var sendOffSeconds: Int     // interval per rep; 0 = none
    var restSeconds: Int        // fixed rest after each rep when no send-off
    var effortRaw: String
    var note: String

    var workout: SwimWorkout?

    init(order: Int,
         repeats: Int,
         distancePerRepMeters: Double,
         stroke: Stroke,
         sendOffSeconds: Int = 0,
         restSeconds: Int = 20,
         effort: Effort = .moderate,
         note: String = "") {
        self.order = order
        self.repeats = max(1, repeats)
        self.distancePerRepMeters = max(0, distancePerRepMeters)
        self.strokeRaw = stroke.rawValue
        self.sendOffSeconds = max(0, sendOffSeconds)
        self.restSeconds = max(0, restSeconds)
        self.effortRaw = effort.rawValue
        self.note = note
    }

    var stroke: Stroke {
        get { Stroke.from(strokeRaw) }
        set { strokeRaw = newValue.rawValue }
    }

    var effort: Effort {
        get { Effort.from(effortRaw) }
        set { effortRaw = newValue.rawValue }
    }

    /// Total distance for the whole set (all reps).
    var totalDistanceMeters: Double {
        Double(max(1, repeats)) * max(0, distancePerRepMeters)
    }
}
