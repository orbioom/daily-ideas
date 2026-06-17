import Foundation

/// Bridges SwiftData sessions into the pure StatsEngine input on the main actor.
enum StatsSnapshot {
    @MainActor
    static func build(from sessions: [WorkoutSession]) -> [StatsEngine.SessionSnapshot] {
        sessions.filter { $0.isComplete }.map { session in
            let lifts = session.orderedExercises.map { ex -> StatsEngine.LiftSnapshot in
                let sets = ex.workingSets
                    .filter { $0.isComplete }
                    .map { (weightKg: $0.weightKg, reps: $0.reps) }
                return StatsEngine.LiftSnapshot(name: ex.name, group: ex.group, sets: sets)
            }
            return StatsEngine.SessionSnapshot(date: session.date, lifts: lifts)
        }
    }
}
