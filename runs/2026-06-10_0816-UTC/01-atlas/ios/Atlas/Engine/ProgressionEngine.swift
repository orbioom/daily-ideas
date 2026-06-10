import Foundation

/// What Atlas recommends for the next session of one exercise.
struct Suggestion: Equatable {
    let weightKg: Double
    let reps: Int
    let reason: String
}

/// Pure progression logic. Given the routine's target scheme and the most
/// recent logged performance of the same exercise, decide what to load next.
enum ProgressionEngine {

    /// `history` is every logged SessionExercise with the same exercise name,
    /// newest first. Only sets marked done count.
    static func suggestion(for exercise: RoutineExercise, history: [SessionExercise]) -> Suggestion {
        guard let last = history.first(where: { $0.sets.contains(where: \.done) }) else {
            return Suggestion(
                weightKg: exercise.startWeightKg,
                reps: exercise.repLow,
                reason: "First session — start light and own the range."
            )
        }

        let doneSets = last.orderedSets.filter(\.done)
        // The working weight last time = the heaviest weight used on a done set.
        let lastWeight = doneSets.map(\.weightKg).max() ?? exercise.startWeightKg
        let workSets = doneSets.filter { abs($0.weightKg - lastWeight) < 0.01 }
        let minReps = workSets.map(\.reps).min() ?? 0
        let hitAllSets = workSets.count >= exercise.targetSets

        switch exercise.progression {
        case .doubleProgression:
            if hitAllSets && minReps >= exercise.repHigh {
                return Suggestion(
                    weightKg: lastWeight + exercise.incrementKg,
                    reps: exercise.repLow,
                    reason: "Every set hit the top of the range — add weight, restart at \(exercise.repLow) reps."
                )
            }
            if hitAllSets && minReps >= exercise.repLow {
                return Suggestion(
                    weightKg: lastWeight,
                    reps: min(exercise.repHigh, minReps + 1),
                    reason: "Same weight — push the lowest set to \(min(exercise.repHigh, minReps + 1)) reps."
                )
            }
            return Suggestion(
                weightKg: lastWeight,
                reps: exercise.repLow,
                reason: "Consolidate — repeat this weight until every set reaches \(exercise.repLow) reps."
            )
        case .linear:
            if hitAllSets && minReps >= exercise.repLow {
                return Suggestion(
                    weightKg: lastWeight + exercise.incrementKg,
                    reps: exercise.repLow,
                    reason: "All sets completed — linear progression adds \(Weight.trim(exercise.incrementKg)) kg."
                )
            }
            return Suggestion(
                weightKg: lastWeight,
                reps: exercise.repLow,
                reason: "Missed a set — repeat this weight before adding more."
            )
        }
    }
}
