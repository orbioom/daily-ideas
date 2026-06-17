import Foundation
import SwiftData

/// A completed swim, with its actual recorded sets.
@Model
final class SwimSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var poolLengthMeters: Double
    var totalDistanceMeters: Double
    var durationSeconds: Int
    var rpe: Int?               // rate of perceived exertion, 1...10
    var notes: String
    var workoutName: String?    // snapshot of the template name, if any

    @Relationship(deleteRule: .cascade, inverse: \CompletedSet.session)
    var sets: [CompletedSet]

    init(id: UUID = UUID(),
         date: Date = .now,
         poolLengthMeters: Double,
         totalDistanceMeters: Double = 0,
         durationSeconds: Int = 0,
         rpe: Int? = nil,
         notes: String = "",
         workoutName: String? = nil,
         sets: [CompletedSet] = []) {
        self.id = id
        self.date = date
        self.poolLengthMeters = poolLengthMeters
        self.totalDistanceMeters = totalDistanceMeters
        self.durationSeconds = durationSeconds
        self.rpe = rpe
        self.notes = notes
        self.workoutName = workoutName
        self.sets = sets
    }

    var orderedSets: [CompletedSet] {
        sets.sorted { $0.order < $1.order }
    }

    /// Recompute distance and duration from the completed sets (defensive).
    func recomputeTotals() {
        let dist = orderedSets.reduce(0) { $0 + $1.totalDistanceMeters }
        let swimTime = orderedSets.reduce(0.0) { $0 + $1.actualTimeSeconds }
        let restTime = orderedSets.reduce(0) { $0 + Double($1.restSeconds * max(1, $1.repeats)) }
        totalDistanceMeters = dist
        if durationSeconds <= 0 {
            durationSeconds = Int((swimTime + restTime).rounded())
        }
    }
}
