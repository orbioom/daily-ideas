import Foundation
import SwiftData

// MARK: - Muscle groups

enum Muscle: String, CaseIterable, Identifiable, Codable {
    case chest, back, shoulders, arms, legs, glutes, core, conditioning

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .legs: return "Legs"
        case .glutes: return "Glutes"
        case .core: return "Core"
        case .conditioning: return "Conditioning"
        }
    }

    var symbol: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.rower"
        case .shoulders: return "figure.martial.arts"
        case .arms: return "figure.strengthtraining.functional"
        case .legs: return "figure.strengthtraining.traditional"
        case .glutes: return "figure.cross.training"
        case .core: return "figure.core.training"
        case .conditioning: return "figure.run"
        }
    }
}

// MARK: - Progression rules

enum ProgressionRule: String, CaseIterable, Identifiable, Codable {
    case doubleProgression = "double"
    case linear = "linear"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .doubleProgression: return "Double progression"
        case .linear: return "Linear"
        }
    }

    var explanation: String {
        switch self {
        case .doubleProgression:
            return "Add reps inside the range first. When every set reaches the top of the range, add weight and start the range over."
        case .linear:
            return "Add weight every session you complete all target sets and reps."
        }
    }
}

// MARK: - Routine (reusable template)

@Model
final class Routine {
    var name: String
    var note: String
    var orderIndex: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise] = []

    init(name: String, note: String = "", orderIndex: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.note = note
        self.orderIndex = orderIndex
        self.createdAt = createdAt
    }

    var orderedExercises: [RoutineExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

@Model
final class RoutineExercise {
    var name: String
    var muscleRaw: String
    var orderIndex: Int
    var targetSets: Int
    var repLow: Int
    var repHigh: Int
    var restSeconds: Int
    var startWeightKg: Double
    var incrementKg: Double
    var progressionRaw: String
    var supersetGroup: Int
    var routine: Routine?

    init(name: String, muscle: Muscle, orderIndex: Int,
         targetSets: Int = 3, repLow: Int = 8, repHigh: Int = 12,
         restSeconds: Int = 120, startWeightKg: Double = 20,
         incrementKg: Double = 2.5, progression: ProgressionRule = .doubleProgression,
         supersetGroup: Int = 0) {
        self.name = name
        self.muscleRaw = muscle.rawValue
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.repLow = repLow
        self.repHigh = repHigh
        self.restSeconds = restSeconds
        self.startWeightKg = startWeightKg
        self.incrementKg = incrementKg
        self.progressionRaw = progression.rawValue
        self.supersetGroup = supersetGroup
    }

    var muscle: Muscle { Muscle(rawValue: muscleRaw) ?? .conditioning }
    var progression: ProgressionRule { ProgressionRule(rawValue: progressionRaw) ?? .doubleProgression }
}

// MARK: - Logged sessions

@Model
final class WorkoutSession {
    var date: Date
    var routineName: String
    var durationSeconds: Int
    var note: String
    var completed: Bool
    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []

    init(date: Date = .now, routineName: String, durationSeconds: Int = 0,
         note: String = "", completed: Bool = true) {
        self.date = date
        self.routineName = routineName
        self.durationSeconds = durationSeconds
        self.note = note
        self.completed = completed
    }

    var orderedExercises: [SessionExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Total weight moved in this session (sum of reps x weight over done sets).
    var tonnageKg: Double {
        exercises.reduce(0) { sum, ex in
            sum + ex.sets.filter(\.done).reduce(0) { $0 + Double($1.reps) * $1.weightKg }
        }
    }

    var doneSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.done).count }
    }
}

@Model
final class SessionExercise {
    var name: String
    var muscleRaw: String
    var orderIndex: Int
    var supersetGroup: Int
    var session: WorkoutSession?
    @Relationship(deleteRule: .cascade, inverse: \SessionSet.exercise)
    var sets: [SessionSet] = []

    init(name: String, muscle: Muscle, orderIndex: Int, supersetGroup: Int = 0) {
        self.name = name
        self.muscleRaw = muscle.rawValue
        self.orderIndex = orderIndex
        self.supersetGroup = supersetGroup
    }

    var muscle: Muscle { Muscle(rawValue: muscleRaw) ?? .conditioning }
    var orderedSets: [SessionSet] { sets.sorted { $0.orderIndex < $1.orderIndex } }
}

@Model
final class SessionSet {
    var orderIndex: Int
    var targetReps: Int
    var reps: Int
    var weightKg: Double
    var done: Bool
    var exercise: SessionExercise?

    init(orderIndex: Int, targetReps: Int, reps: Int, weightKg: Double, done: Bool) {
        self.orderIndex = orderIndex
        self.targetReps = targetReps
        self.reps = reps
        self.weightKg = weightKg
        self.done = done
    }
}
