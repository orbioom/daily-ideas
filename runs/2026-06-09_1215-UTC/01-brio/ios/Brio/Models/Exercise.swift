import Foundation
import SwiftData

/// A single movement in the exercise library. Built-in exercises seed on first
/// launch; users could add their own. Workouts reference these by snapshotting
/// the relevant fields into `WorkoutItem` so edits stay isolated.
@Model
final class Exercise {
    var name: String
    var detail: String          // one-sentence instructions
    var muscleGroupRaw: String
    var kindRaw: String
    var defaultReps: Int
    var defaultDurationSec: Int
    var needsEquipment: Bool
    var symbol: String
    var isBuiltIn: Bool
    var createdAt: Date

    init(name: String,
         detail: String,
         muscleGroup: MuscleGroup,
         kind: ExerciseKind,
         defaultReps: Int = 12,
         defaultDurationSec: Int = 30,
         needsEquipment: Bool = false,
         symbol: String = "figure.strengthtraining.functional",
         isBuiltIn: Bool = false) {
        self.name = name
        self.detail = detail
        self.muscleGroupRaw = muscleGroup.rawValue
        self.kindRaw = kind.rawValue
        self.defaultReps = min(max(defaultReps, 1), 100)
        self.defaultDurationSec = min(max(defaultDurationSec, 5), 600)
        self.needsEquipment = needsEquipment
        self.symbol = symbol
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var kind: ExerciseKind {
        get { ExerciseKind(rawValue: kindRaw) ?? .reps }
        set { kindRaw = newValue.rawValue }
    }
}
