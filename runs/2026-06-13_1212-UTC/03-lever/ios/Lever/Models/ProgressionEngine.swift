import Foundation

/// The structured plan for one set within a guided session.
struct PlannedSet: Identifiable {
    let id = UUID()
    let index: Int          // 0-based set number
    let target: Int         // reps or seconds
    let restSeconds: Int    // rest *after* this set (0 for the final set)
}

/// A full session plan: the level being trained plus its ordered sets.
struct SessionPlan: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let level: ProgressionLevel
    let sets: [PlannedSet]

    var totalSets: Int { sets.count }
}

/// Pure, fully-guarded progression logic. No persistence, no UI, no crashing.
enum ProgressionEngine {

    /// Place a user on the ladder from an all-out test result. We pick the
    /// highest level whose per-set target the result comfortably clears, so the
    /// user starts where they can actually complete the prescribed sets.
    static func recommendedLevel(exercise: Exercise, maxRepsOrSeconds: Int) -> Int {
        guard !exercise.levels.isEmpty else { return 0 }
        let value = max(0, maxRepsOrSeconds)
        var placement = 0
        for level in exercise.levels {
            // A single all-out set should beat one prescribed set with margin.
            if value >= level.target {
                placement = level.index
            } else {
                break
            }
        }
        return min(placement, exercise.levels.count - 1)
    }

    /// Build the set/rest/target structure for a level.
    static func sessionPlan(exercise: Exercise, level: ProgressionLevel) -> SessionPlan {
        let count = max(1, level.targetSets)
        let sets = (0..<count).map { i in
            PlannedSet(index: i,
                       target: max(1, level.target),
                       restSeconds: i < count - 1 ? max(0, level.restSeconds) : 0)
        }
        return SessionPlan(exercise: exercise, level: level, sets: sets)
    }

    /// True when the user has hit the level's per-set target across *all* sets
    /// in their two most recent sessions at this level — earning the next rung.
    static func shouldAdvance(level: ProgressionLevel, recentLogs: [WorkoutLog]) -> Bool {
        let atLevel = recentLogs
            .filter { $0.levelIndex == level.index }
            .sorted { $0.date > $1.date }
            .prefix(2)
        guard atLevel.count >= 2 else { return false }
        return atLevel.allSatisfy { $0.hitTarget(level.target) }
    }
}
