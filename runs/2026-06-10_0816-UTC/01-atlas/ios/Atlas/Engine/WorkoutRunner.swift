import Foundation
import Observation
import SwiftData

struct PlannedSet: Identifiable {
    let id = UUID()
    var targetReps: Int
    var reps: Int
    var weightKg: Double
    var done: Bool = false
}

struct PlannedExercise: Identifiable {
    let id = UUID()
    let name: String
    let muscle: Muscle
    let restSeconds: Int
    let supersetGroup: Int
    let suggestionReason: String
    var sets: [PlannedSet]

    var doneCount: Int { sets.filter(\.done).count }
}

/// Live state of one workout. Owns the plan (prefilled by the progression
/// engine), the elapsed clock, and the date-based rest timer.
@Observable
final class WorkoutRunner: Identifiable {
    let id = UUID()
    let routineName: String
    let startedAt = Date()
    var exercises: [PlannedExercise]
    var restEndDate: Date?
    var restLength: Int = 0
    var note: String = ""

    init(routine: Routine, priorSessions: [WorkoutSession]) {
        routineName = routine.name
        // Newest-first flat history of logged exercises, for the engine.
        let logged = priorSessions
            .sorted { $0.date > $1.date }
            .flatMap { session in session.orderedExercises }

        exercises = routine.orderedExercises.map { ex in
            let history = logged.filter { $0.name == ex.name }
            let s = ProgressionEngine.suggestion(for: ex, history: history)
            return PlannedExercise(
                name: ex.name,
                muscle: ex.muscle,
                restSeconds: ex.restSeconds,
                supersetGroup: ex.supersetGroup,
                suggestionReason: s.reason,
                sets: (0..<max(1, ex.targetSets)).map { _ in
                    PlannedSet(targetReps: s.reps, reps: s.reps, weightKg: s.weightKg)
                }
            )
        }
    }

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }
    var doneSets: Int { exercises.reduce(0) { $0 + $1.doneCount } }
    var progress: Double { totalSets == 0 ? 0 : Double(doneSets) / Double(totalSets) }

    func toggleSet(exercise exIndex: Int, set setIndex: Int) {
        guard exercises.indices.contains(exIndex),
              exercises[exIndex].sets.indices.contains(setIndex) else { return }
        exercises[exIndex].sets[setIndex].done.toggle()
        if exercises[exIndex].sets[setIndex].done {
            startRest(seconds: exercises[exIndex].restSeconds)
        }
    }

    func addSet(exercise exIndex: Int) {
        guard exercises.indices.contains(exIndex),
              let last = exercises[exIndex].sets.last else { return }
        exercises[exIndex].sets.append(
            PlannedSet(targetReps: last.targetReps, reps: last.reps, weightKg: last.weightKg)
        )
    }

    func removeSet(exercise exIndex: Int) {
        guard exercises.indices.contains(exIndex),
              exercises[exIndex].sets.count > 1 else { return }
        exercises[exIndex].sets.removeLast()
    }

    // MARK: Rest timer (date-based, survives backgrounding)

    func startRest(seconds: Int) {
        guard seconds > 0 else { return }
        restLength = seconds
        restEndDate = Date().addingTimeInterval(TimeInterval(seconds))
    }

    func extendRest(by seconds: Int) {
        guard let end = restEndDate else { return }
        restEndDate = end.addingTimeInterval(TimeInterval(seconds))
        restLength += seconds
    }

    func skipRest() {
        restEndDate = nil
    }

    func restRemaining(at date: Date) -> Int? {
        guard let end = restEndDate else { return nil }
        let r = Int(end.timeIntervalSince(date).rounded(.up))
        return r > 0 ? r : nil
    }

    /// Writes the finished workout into SwiftData. Only exercises with at
    /// least one done set are kept; empty workouts save nothing.
    @discardableResult
    func finish(into context: ModelContext) -> WorkoutSession? {
        let performed = exercises.filter { $0.doneCount > 0 }
        guard !performed.isEmpty else { return nil }

        let session = WorkoutSession(
            date: startedAt,
            routineName: routineName,
            durationSeconds: Int(Date().timeIntervalSince(startedAt)),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            completed: true
        )
        context.insert(session)
        session.exercises = performed.enumerated().map { index, plan in
            let ex = SessionExercise(name: plan.name, muscle: plan.muscle,
                                     orderIndex: index, supersetGroup: plan.supersetGroup)
            ex.sets = plan.sets.enumerated().map { setIndex, s in
                SessionSet(orderIndex: setIndex, targetReps: s.targetReps,
                           reps: s.reps, weightKg: s.weightKg, done: s.done)
            }
            return ex
        }
        return session
    }
}
