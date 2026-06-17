import Foundation
import SwiftData

/// A reusable workout template/plan made of ordered sets.
@Model
final class SwimWorkout {
    @Attribute(.unique) var id: UUID
    var name: String
    var poolLengthMeters: Double
    var typeRaw: String
    var notes: String
    var createdAt: Date
    var isBuiltIn: Bool

    @Relationship(deleteRule: .cascade, inverse: \SwimSet.workout)
    var sets: [SwimSet]

    init(id: UUID = UUID(),
         name: String,
         poolLengthMeters: Double,
         type: WorkoutType,
         notes: String = "",
         createdAt: Date = .now,
         isBuiltIn: Bool = false,
         sets: [SwimSet] = []) {
        self.id = id
        self.name = name
        self.poolLengthMeters = poolLengthMeters
        self.typeRaw = type.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.isBuiltIn = isBuiltIn
        self.sets = sets
    }

    var type: WorkoutType {
        get { WorkoutType.from(typeRaw) }
        set { typeRaw = newValue.rawValue }
    }

    /// Sets in their intended order.
    var orderedSets: [SwimSet] {
        sets.sorted { $0.order < $1.order }
    }

    /// Total planned distance in meters.
    var totalDistanceMeters: Double {
        WorkoutMath.totalDistance(of: orderedSets)
    }
}
