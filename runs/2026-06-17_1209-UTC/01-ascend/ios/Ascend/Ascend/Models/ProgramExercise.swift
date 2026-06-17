import Foundation
import SwiftData

/// A prescribed exercise inside a program day.
@Model
final class ProgramExercise {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Stored raw; access via `muscleGroup`.
    var muscleGroupRaw: String
    var sets: Int
    var reps: Int
    var startingWeightKg: Double
    var incrementKg: Double
    var isAccessory: Bool
    var order: Int
    var day: ProgramDay?

    init(name: String,
         muscleGroup: MuscleGroup,
         sets: Int,
         reps: Int,
         startingWeightKg: Double,
         incrementKg: Double,
         isAccessory: Bool = false,
         order: Int) {
        self.id = UUID()
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.sets = max(sets, 1)
        self.reps = max(reps, 1)
        self.startingWeightKg = max(startingWeightKg, 0)
        self.incrementKg = max(incrementKg, 0)
        self.isAccessory = isAccessory
        self.order = order
    }

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .chest }
        set { muscleGroupRaw = newValue.rawValue }
    }
}
