import Foundation

/// The unit a level's target is measured in.
enum ExerciseUnit: String, Codable {
    case reps
    case seconds

    var short: String { self == .reps ? "reps" : "sec" }
    var verb: String { self == .reps ? "Reps" : "Hold" }
}

/// One rung on an exercise's skill ladder.
struct ProgressionLevel: Identifiable, Hashable {
    let index: Int
    let name: String
    let detail: String
    let targetSets: Int
    /// Per-set target — interpreted as reps or seconds depending on the exercise unit.
    let target: Int
    let restSeconds: Int
    let tip: String
    /// Pro-only advanced rungs are gated behind the paywall.
    var isPro: Bool = false

    var id: Int { index }
}

/// A bodyweight movement with a ladder of progression levels.
struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let muscleGroup: String
    let icon: String          // SF Symbol
    let unit: ExerciseUnit
    let levels: [ProgressionLevel]

    /// True if any rung on the ladder is Pro-only.
    var hasProLevels: Bool { levels.contains { $0.isPro } }

    /// Safe level lookup, clamped into range.
    func level(at index: Int) -> ProgressionLevel? {
        guard !levels.isEmpty else { return nil }
        let clamped = min(max(index, 0), levels.count - 1)
        return levels[clamped]
    }

    static func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Exercise, rhs: Exercise) -> Bool { lhs.id == rhs.id }
}
