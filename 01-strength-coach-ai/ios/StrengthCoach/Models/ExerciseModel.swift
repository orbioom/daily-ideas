import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String // Chest, Back, Legs, Shoulders, Arms, Core
    var equipment: String // Barbell, Dumbbell, Machine, Bodyweight
    var repRange: String // 3-5, 6-8, 8-12, 12-15
    var createdAt: Date

    init(name: String, category: String, equipment: String, repRange: String) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.equipment = equipment
        self.repRange = repRange
        self.createdAt = Date()
    }
}

@Model
final class Set {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var reps: Int
    var rpe: Int? // 6-10 Rate of Perceived Exertion

    init(weight: Double, reps: Int, rpe: Int? = nil) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
    }
}

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var exercises: [SessionExercise] = []
    var date: Date
    var duration: Int // minutes
    var notes: String
    var feeling: Int // 1-5

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.duration = 0
        self.notes = ""
        self.feeling = 3
    }
}

@Model
final class SessionExercise {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    @Relationship(deleteRule: .cascade) var sets: [Set] = []
    var order: Int
    var restTime: Int // seconds

    init(exerciseName: String, order: Int = 0) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.order = order
        self.restTime = 90
    }
}

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise] = []
    var name: String
    var description: String
    var createdAt: Date

    init(name: String, description: String = "") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.createdAt = Date()
    }
}

@Model
final class WorkoutExercise {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var sets: Int
    var reps: [Int] // target reps per set
    var weight: [Double] // suggested weight per set
    var order: Int
    var notes: String
    var lastPerformed: Date?

    init(exerciseName: String, sets: Int = 3, order: Int = 0) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = Array(repeating: 8, count: sets)
        self.weight = Array(repeating: 135.0, count: sets)
        self.order = order
        self.notes = ""
    }
}

@Model
final class ProgressionEntry {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var date: Date
    var weight: Double
    var reps: Int
    var rpe: Int?
    var estimated1RM: Double

    init(exerciseName: String, weight: Double, reps: Int, rpe: Int? = nil) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.date = Date()
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.estimated1RM = ProgressionEngine.estimate1RM(weight: weight, reps: reps)
    }
}

struct ProgressionEngine {
    static func estimate1RM(weight: Double, reps: Int) -> Double {
        if reps == 1 { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }

    static func suggestNextWeight(lastWeight: Double, lastReps: Int, targetReps: Int) -> Double {
        let oneRM = estimate1RM(weight: lastWeight, reps: lastReps)
        let nextWeight = oneRM * (0.85 + Double(targetReps) * 0.01)
        return (nextWeight / 5).rounded() * 5 // Round to nearest 5
    }
}
