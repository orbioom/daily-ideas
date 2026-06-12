import Foundation
import SwiftData

/// A persisted snapshot of one calendar day's walking activity. CoreMotion
/// only retains the last ~7 days of pedometer data, so Tread caches each day
/// into SwiftData as it is observed — that is how longer-range insights and
/// streaks survive beyond the sensor's own window.
@Model
final class DayLog {
    /// Start-of-day, the unique key for the record.
    @Attribute(.unique) var day: Date
    var steps: Int
    var distanceMeters: Double
    var flights: Int
    /// The goal that was in force for this day (so history reflects the goal
    /// you actually had, not today's).
    var goal: Int
    /// True when the figures came from a real motion sensor (vs demo data).
    var fromSensor: Bool

    init(day: Date, steps: Int, distanceMeters: Double, flights: Int, goal: Int, fromSensor: Bool) {
        self.day = day
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.flights = flights
        self.goal = goal
        self.fromSensor = fromSensor
    }

    var metGoal: Bool { goal > 0 && steps >= goal }
    var progress: Double { goal > 0 ? min(Double(steps) / Double(goal), 1) : 0 }
}
