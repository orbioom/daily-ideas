import Foundation
import SwiftData

/// A pickable exercise from the built-in library.
struct CatalogExercise: Identifiable, Hashable {
    let name: String
    let muscle: Muscle
    var id: String { name }
}

enum ExerciseCatalog {

    static let all: [CatalogExercise] = [
        // Chest
        .init(name: "Barbell Bench Press", muscle: .chest),
        .init(name: "Incline Dumbbell Press", muscle: .chest),
        .init(name: "Dumbbell Bench Press", muscle: .chest),
        .init(name: "Cable Fly", muscle: .chest),
        .init(name: "Push-Up", muscle: .chest),
        .init(name: "Machine Chest Press", muscle: .chest),
        .init(name: "Dip", muscle: .chest),
        // Back
        .init(name: "Deadlift", muscle: .back),
        .init(name: "Barbell Row", muscle: .back),
        .init(name: "Pull-Up", muscle: .back),
        .init(name: "Chin-Up", muscle: .back),
        .init(name: "Lat Pulldown", muscle: .back),
        .init(name: "Seated Cable Row", muscle: .back),
        .init(name: "Single-Arm Dumbbell Row", muscle: .back),
        .init(name: "T-Bar Row", muscle: .back),
        .init(name: "Face Pull", muscle: .back),
        // Shoulders
        .init(name: "Overhead Press", muscle: .shoulders),
        .init(name: "Seated Dumbbell Press", muscle: .shoulders),
        .init(name: "Lateral Raise", muscle: .shoulders),
        .init(name: "Rear Delt Fly", muscle: .shoulders),
        .init(name: "Arnold Press", muscle: .shoulders),
        .init(name: "Upright Row", muscle: .shoulders),
        // Arms
        .init(name: "Barbell Curl", muscle: .arms),
        .init(name: "Dumbbell Curl", muscle: .arms),
        .init(name: "Hammer Curl", muscle: .arms),
        .init(name: "Preacher Curl", muscle: .arms),
        .init(name: "Triceps Pushdown", muscle: .arms),
        .init(name: "Skull Crusher", muscle: .arms),
        .init(name: "Overhead Triceps Extension", muscle: .arms),
        .init(name: "Close-Grip Bench Press", muscle: .arms),
        // Legs
        .init(name: "Back Squat", muscle: .legs),
        .init(name: "Front Squat", muscle: .legs),
        .init(name: "Leg Press", muscle: .legs),
        .init(name: "Romanian Deadlift", muscle: .legs),
        .init(name: "Leg Extension", muscle: .legs),
        .init(name: "Leg Curl", muscle: .legs),
        .init(name: "Walking Lunge", muscle: .legs),
        .init(name: "Bulgarian Split Squat", muscle: .legs),
        .init(name: "Calf Raise", muscle: .legs),
        .init(name: "Goblet Squat", muscle: .legs),
        // Glutes
        .init(name: "Hip Thrust", muscle: .glutes),
        .init(name: "Glute Bridge", muscle: .glutes),
        .init(name: "Cable Kickback", muscle: .glutes),
        .init(name: "Sumo Deadlift", muscle: .glutes),
        // Core
        .init(name: "Plank", muscle: .core),
        .init(name: "Hanging Leg Raise", muscle: .core),
        .init(name: "Cable Crunch", muscle: .core),
        .init(name: "Ab Wheel Rollout", muscle: .core),
        .init(name: "Russian Twist", muscle: .core),
        // Conditioning
        .init(name: "Kettlebell Swing", muscle: .conditioning),
        .init(name: "Farmer's Carry", muscle: .conditioning),
        .init(name: "Sled Push", muscle: .conditioning),
        .init(name: "Burpee", muscle: .conditioning)
    ]

    static func grouped() -> [(muscle: Muscle, exercises: [CatalogExercise])] {
        Muscle.allCases.compactMap { m in
            let items = all.filter { $0.muscle == m }
            return items.isEmpty ? nil : (m, items)
        }
    }
}

// MARK: - Starter program

enum StarterProgram {

    /// Installs a balanced 4-day starter split. Weights start light on purpose;
    /// the progression engine takes over from the first logged session.
    static func install(into context: ModelContext) {
        let a = Routine(name: "Full Body A", note: "Squat-focused full body. 2-3 days/week alternating with Full Body B.", orderIndex: 0)
        context.insert(a)
        a.exercises = [
            RoutineExercise(name: "Back Squat", muscle: .legs, orderIndex: 0, targetSets: 3, repLow: 5, repHigh: 8, restSeconds: 180, startWeightKg: 40, incrementKg: 2.5),
            RoutineExercise(name: "Barbell Bench Press", muscle: .chest, orderIndex: 1, targetSets: 3, repLow: 5, repHigh: 8, restSeconds: 180, startWeightKg: 30, incrementKg: 2.5),
            RoutineExercise(name: "Barbell Row", muscle: .back, orderIndex: 2, targetSets: 3, repLow: 6, repHigh: 10, restSeconds: 150, startWeightKg: 30, incrementKg: 2.5),
            RoutineExercise(name: "Lateral Raise", muscle: .shoulders, orderIndex: 3, targetSets: 3, repLow: 10, repHigh: 15, restSeconds: 90, startWeightKg: 5, incrementKg: 1),
            RoutineExercise(name: "Plank", muscle: .core, orderIndex: 4, targetSets: 3, repLow: 1, repHigh: 1, restSeconds: 60, startWeightKg: 0, incrementKg: 0)
        ]

        let b = Routine(name: "Full Body B", note: "Hinge-focused full body. Alternate with Full Body A.", orderIndex: 1)
        context.insert(b)
        b.exercises = [
            RoutineExercise(name: "Deadlift", muscle: .back, orderIndex: 0, targetSets: 3, repLow: 3, repHigh: 6, restSeconds: 210, startWeightKg: 50, incrementKg: 5),
            RoutineExercise(name: "Overhead Press", muscle: .shoulders, orderIndex: 1, targetSets: 3, repLow: 5, repHigh: 8, restSeconds: 180, startWeightKg: 20, incrementKg: 2.5),
            RoutineExercise(name: "Lat Pulldown", muscle: .back, orderIndex: 2, targetSets: 3, repLow: 8, repHigh: 12, restSeconds: 120, startWeightKg: 30, incrementKg: 2.5),
            RoutineExercise(name: "Walking Lunge", muscle: .legs, orderIndex: 3, targetSets: 3, repLow: 8, repHigh: 12, restSeconds: 120, startWeightKg: 10, incrementKg: 2.5),
            RoutineExercise(name: "Hanging Leg Raise", muscle: .core, orderIndex: 4, targetSets: 3, repLow: 8, repHigh: 15, restSeconds: 60, startWeightKg: 0, incrementKg: 0)
        ]

        let upper = Routine(name: "Upper Body", note: "Push/pull pairing with supersets on the accessories.", orderIndex: 2)
        context.insert(upper)
        upper.exercises = [
            RoutineExercise(name: "Barbell Bench Press", muscle: .chest, orderIndex: 0, targetSets: 4, repLow: 6, repHigh: 10, restSeconds: 180, startWeightKg: 30, incrementKg: 2.5),
            RoutineExercise(name: "Barbell Row", muscle: .back, orderIndex: 1, targetSets: 4, repLow: 6, repHigh: 10, restSeconds: 180, startWeightKg: 30, incrementKg: 2.5),
            RoutineExercise(name: "Dumbbell Curl", muscle: .arms, orderIndex: 2, targetSets: 3, repLow: 10, repHigh: 15, restSeconds: 90, startWeightKg: 8, incrementKg: 1, supersetGroup: 1),
            RoutineExercise(name: "Triceps Pushdown", muscle: .arms, orderIndex: 3, targetSets: 3, repLow: 10, repHigh: 15, restSeconds: 90, startWeightKg: 15, incrementKg: 2.5, supersetGroup: 1)
        ]

        let lower = Routine(name: "Lower Body", note: "Squat + hinge + single-leg work.", orderIndex: 3)
        context.insert(lower)
        lower.exercises = [
            RoutineExercise(name: "Back Squat", muscle: .legs, orderIndex: 0, targetSets: 4, repLow: 5, repHigh: 8, restSeconds: 180, startWeightKg: 40, incrementKg: 2.5),
            RoutineExercise(name: "Romanian Deadlift", muscle: .legs, orderIndex: 1, targetSets: 3, repLow: 8, repHigh: 12, restSeconds: 150, startWeightKg: 40, incrementKg: 2.5),
            RoutineExercise(name: "Bulgarian Split Squat", muscle: .legs, orderIndex: 2, targetSets: 3, repLow: 8, repHigh: 12, restSeconds: 120, startWeightKg: 8, incrementKg: 1),
            RoutineExercise(name: "Calf Raise", muscle: .legs, orderIndex: 3, targetSets: 3, repLow: 12, repHigh: 20, restSeconds: 60, startWeightKg: 20, incrementKg: 2.5, supersetGroup: 1),
            RoutineExercise(name: "Cable Crunch", muscle: .core, orderIndex: 4, targetSets: 3, repLow: 10, repHigh: 15, restSeconds: 60, startWeightKg: 15, incrementKg: 2.5, supersetGroup: 1)
        ]
    }
}
