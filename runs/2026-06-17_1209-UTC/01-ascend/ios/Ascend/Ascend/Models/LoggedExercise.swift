import Foundation
import SwiftData

/// One exercise logged within a session, with its sets.
@Model
final class LoggedExercise {
    @Attribute(.unique) var id: UUID
    var name: String
    /// MuscleGroup rawValue.
    var muscleGroup: String
    var order: Int
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.exercise)
    var sets: [LoggedSet]

    init(name: String, muscleGroup: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.order = order
        self.sets = []
    }

    var group: MuscleGroup {
        MuscleGroup(rawValue: muscleGroup) ?? .chest
    }

    var orderedSets: [LoggedSet] {
        sets.sorted { $0.setIndex < $1.setIndex }
    }

    var workingSets: [LoggedSet] {
        orderedSets.filter { !$0.isWarmup }
    }
}
