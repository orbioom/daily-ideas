import Foundation
import SwiftData

/// A single logged set: weight × reps, optional RPE, with warm-up flag.
/// Weight is always stored in kilograms; the UI converts for display.
@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    var order: Int
    var weightKg: Double
    var reps: Int
    var rpe: Double?
    var isWarmup: Bool
    var isCompleted: Bool
    var loggedAt: Date

    var workout: Workout?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int = 0,
        weightKg: Double = 0,
        reps: Int = 0,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        loggedAt: Date = .now,
        workout: Workout? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.weightKg = max(0, weightKg)
        self.reps = max(0, reps)
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.loggedAt = loggedAt
        self.workout = workout
        self.exercise = exercise
    }

    /// Working volume (warm-ups excluded).
    var volume: Double {
        isWarmup ? 0 : weightKg * Double(reps)
    }

    /// Estimated one-rep max via the Epley formula. Returns nil for warm-ups,
    /// bodyweight-only entries, or zero reps.
    var estimatedOneRepMax: Double? {
        StrengthMath.epley(weightKg: weightKg, reps: reps, warmup: isWarmup)
    }
}
