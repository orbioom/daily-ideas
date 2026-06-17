import Foundation
import SwiftData

/// A single logged set: weight (kg), reps, warmup/complete flags.
@Model
final class LoggedSet {
    @Attribute(.unique) var id: UUID
    var setIndex: Int
    var weightKg: Double
    var reps: Int
    var isWarmup: Bool
    var isComplete: Bool
    var exercise: LoggedExercise?

    init(setIndex: Int,
         weightKg: Double,
         reps: Int,
         isWarmup: Bool = false,
         isComplete: Bool = false) {
        self.id = UUID()
        self.setIndex = setIndex
        self.weightKg = max(weightKg, 0)
        self.reps = max(reps, 0)
        self.isWarmup = isWarmup
        self.isComplete = isComplete
    }
}
