import Foundation
import SwiftData

/// One movement slot inside a workout. Snapshots the exercise's name/kind/symbol
/// at the time it was added so later edits to the library don't mutate saved
/// workouts. `perSide` doubles the work (e.g. lunges left then right).
@Model
final class WorkoutItem {
    var order: Int
    var exerciseName: String
    var kindRaw: String
    var reps: Int
    var durationSec: Int
    var perSide: Bool
    var symbol: String

    var workout: Workout?

    init(order: Int,
         exerciseName: String,
         kind: ExerciseKind,
         reps: Int = 12,
         durationSec: Int = 30,
         perSide: Bool = false,
         symbol: String = "figure.strengthtraining.functional") {
        self.order = order
        self.exerciseName = exerciseName
        self.kindRaw = kind.rawValue
        self.reps = min(max(reps, 1), 100)
        self.durationSec = min(max(durationSec, 5), 600)
        self.perSide = perSide
        self.symbol = symbol
    }

    var kind: ExerciseKind {
        get { ExerciseKind(rawValue: kindRaw) ?? .reps }
        set { kindRaw = newValue.rawValue }
    }

    /// Builds an item from a library exercise, copying its defaults.
    convenience init(from exercise: Exercise, order: Int) {
        self.init(order: order,
                  exerciseName: exercise.name,
                  kind: exercise.kind,
                  reps: exercise.defaultReps,
                  durationSec: exercise.defaultDurationSec,
                  perSide: false,
                  symbol: exercise.symbol)
    }

    var detailLine: String {
        switch kind {
        case .reps:
            return perSide ? "\(reps) reps / side" : "\(reps) reps"
        case .timed:
            return perSide ? "\(durationSec)s / side" : "\(durationSec)s"
        }
    }
}
