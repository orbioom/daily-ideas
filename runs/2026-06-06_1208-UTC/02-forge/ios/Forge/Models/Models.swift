import Foundation
import SwiftData

/// A movement in the lifter's catalog (e.g. "Back Squat"). Sets reference it.
@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var groupRaw: String = MuscleGroup.other.rawValue
    var isBodyweight: Bool = false
    var notes: String = ""
    var createdAt: Date = Date()

    init(name: String, group: MuscleGroup = .other, isBodyweight: Bool = false) {
        self.name = name
        self.groupRaw = group.rawValue
        self.isBodyweight = isBodyweight
    }
    var group: MuscleGroup {
        get { MuscleGroup(rawValue: groupRaw) ?? .other }
        set { groupRaw = newValue.rawValue }
    }
}

/// A training session on a date, owning the sets performed.
@Model
final class Workout {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String = ""
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.workout)
    var sets: [SetEntry] = []

    init(date: Date = Date(), title: String = "") {
        self.date = date
        self.title = title
    }

    var orderedSets: [SetEntry] { sets.sorted { $0.order < $1.order } }
    /// Total kg lifted (weight × reps) across working sets.
    var volumeKg: Double { sets.filter { !$0.isWarmup }.reduce(0) { $0 + $1.volumeKg } }
    var workingSetCount: Int { sets.filter { !$0.isWarmup }.count }

    /// Distinct exercises in stable encounter order.
    var exercisesInOrder: [Exercise] {
        var seen = Set<UUID>()
        var result: [Exercise] = []
        for s in orderedSets {
            if let ex = s.exercise, !seen.contains(ex.id) {
                seen.insert(ex.id); result.append(ex)
            }
        }
        return result
    }
}

/// A single set: weight (kg), reps, optional RPE, warm-up flag.
@Model
final class SetEntry {
    var id: UUID = UUID()
    var weightKg: Double = 0
    var reps: Int = 0
    var rpe: Double = 0      // 0 = not recorded
    var isWarmup: Bool = false
    var order: Int = 0
    var workout: Workout?
    var exercise: Exercise?

    init(exercise: Exercise?, weightKg: Double = 0, reps: Int = 0, order: Int = 0) {
        self.exercise = exercise
        self.weightKg = max(0, weightKg)
        self.reps = max(0, reps)
        self.order = order
    }

    var volumeKg: Double { weightKg * Double(max(0, reps)) }
}
