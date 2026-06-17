import Foundation
import SwiftData

/// Decides the next prescribed weight for an exercise based on recent performance.
/// Linear progression: succeed → +increment; 3 consecutive failures → deload 10%.
enum ProgressionEngine {

    struct Prescription {
        let weightKg: Double
        let sets: Int
        let reps: Int
        /// How the weight was derived, for UI explanation.
        let reason: Reason
        let consecutiveFailures: Int
    }

    enum Reason {
        case starting          // no history yet
        case progressed        // hit all targets, added weight
        case repeated          // missed, hold weight
        case deloaded          // 3 misses, dropped 10%
    }

    /// Compute the next prescription for `exerciseName` in the given program.
    /// Looks at completed sessions for the program, newest first.
    static func nextPrescription(for exercise: ProgramExercise,
                                 exerciseName: String,
                                 in program: Program,
                                 context: ModelContext) -> Prescription {
        let history = completedHistory(programName: program.name,
                                       exerciseName: exerciseName,
                                       context: context)

        guard let last = history.first else {
            return Prescription(weightKg: exercise.startingWeightKg,
                                sets: exercise.sets,
                                reps: exercise.reps,
                                reason: .starting,
                                consecutiveFailures: 0)
        }

        let increment = exercise.incrementKg
        let target = exercise.reps
        let lastWeight = last.topWorkingWeightKg

        if last.metTarget(reps: target) {
            // Success: add weight, reset the failure streak.
            let next = lastWeight + increment
            return Prescription(weightKg: next,
                                sets: exercise.sets,
                                reps: target,
                                reason: increment > 0 ? .progressed : .repeated,
                                consecutiveFailures: 0)
        }

        // A miss. Count how many sessions in a row (most recent first) missed.
        var fails = 0
        for entry in history {
            if entry.metTarget(reps: target) { break }
            fails += 1
        }

        if fails >= 3 {
            // Deload 10%, rounded to nearest 2.5 kg.
            let deloaded = Units.roundToPlate(lastWeight * 0.9, step: 2.5)
            return Prescription(weightKg: deloaded,
                                sets: exercise.sets,
                                reps: target,
                                reason: .deloaded,
                                consecutiveFailures: 0)
        }

        // Repeat the same weight.
        return Prescription(weightKg: lastWeight,
                            sets: exercise.sets,
                            reps: target,
                            reason: .repeated,
                            consecutiveFailures: fails)
    }

    // MARK: History snapshot

    /// A compact view of one exercise's performance in one past session.
    struct ExercisePerformance {
        let date: Date
        let workingSets: [(weightKg: Double, reps: Int, complete: Bool)]

        /// The heaviest weight used across completed working sets.
        var topWorkingWeightKg: Double {
            workingSets.filter { $0.complete }.map { $0.weightKg }.max() ?? 0
        }

        /// True if every completed working set at the top weight hit the target reps.
        func metTarget(reps target: Int) -> Bool {
            let top = topWorkingWeightKg
            guard top > 0 else { return false }
            let atTop = workingSets.filter { $0.complete && abs($0.weightKg - top) < 0.01 }
            guard !atTop.isEmpty else { return false }
            return atTop.allSatisfy { $0.reps >= target }
        }
    }

    /// All completed performances for an exercise in a program, newest first.
    static func completedHistory(programName: String,
                                 exerciseName: String,
                                 context: ModelContext) -> [ExercisePerformance] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isComplete && $0.programName == programName },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let sessions = try? context.fetch(descriptor) else { return [] }

        var out: [ExercisePerformance] = []
        for session in sessions {
            guard let ex = session.orderedExercises.first(where: { $0.name == exerciseName }) else { continue }
            let working = ex.workingSets.map {
                (weightKg: $0.weightKg, reps: $0.reps, complete: $0.isComplete)
            }
            guard working.contains(where: { $0.complete }) else { continue }
            out.append(ExercisePerformance(date: session.date, workingSets: working))
        }
        return out
    }
}
