import Foundation

/// Factory for the built-in programs. Weights are canonical kg.
enum BuiltInPrograms {

    /// A lightweight blueprint, turned into SwiftData models on demand.
    struct Blueprint: Identifiable {
        let id = UUID()
        let type: ProgramType
        let name: String
        let summary: String
        let days: [DayBlueprint]
        var requiresPro: Bool { type.requiresPro }
    }

    struct DayBlueprint {
        let name: String
        let exercises: [ExerciseBlueprint]
    }

    struct ExerciseBlueprint {
        let name: String
        let group: MuscleGroup
        let sets: Int
        let reps: Int
        let startKg: Double
        let incrementKg: Double
        var isAccessory: Bool = false
    }

    /// All free + Pro blueprints, in display order.
    static let all: [Blueprint] = [strongLifts5x5, pushPullLegs, upperLower, fullBody3]

    /// Build live SwiftData models from a blueprint (not yet inserted).
    static func makeProgram(from bp: Blueprint, isActive: Bool) -> Program {
        let program = Program(name: bp.name, type: bp.type, notes: bp.summary, isActive: isActive)
        for (di, day) in bp.days.enumerated() {
            let pd = ProgramDay(name: day.name, order: di)
            for (ei, ex) in day.exercises.enumerated() {
                let pe = ProgramExercise(name: ex.name,
                                         muscleGroup: ex.group,
                                         sets: ex.sets,
                                         reps: ex.reps,
                                         startingWeightKg: ex.startKg,
                                         incrementKg: ex.incrementKg,
                                         isAccessory: ex.isAccessory,
                                         order: ei)
                pe.day = pd
                pd.exercises.append(pe)
            }
            pd.program = program
            program.days.append(pd)
        }
        return program
    }

    // MARK: Blueprints

    static let strongLifts5x5 = Blueprint(
        type: .linear5x5,
        name: "StrongLifts 5×5",
        summary: "Two alternating full-body days. 5×5 on the big lifts, 1×5 deadlift. Add 2.5 kg each session.",
        days: [
            DayBlueprint(name: "Workout A", exercises: [
                ExerciseBlueprint(name: "Squat", group: .legs, sets: 5, reps: 5, startKg: 40, incrementKg: 2.5),
                ExerciseBlueprint(name: "Bench Press", group: .chest, sets: 5, reps: 5, startKg: 30, incrementKg: 2.5),
                ExerciseBlueprint(name: "Barbell Row", group: .back, sets: 5, reps: 5, startKg: 30, incrementKg: 2.5)
            ]),
            DayBlueprint(name: "Workout B", exercises: [
                ExerciseBlueprint(name: "Squat", group: .legs, sets: 5, reps: 5, startKg: 40, incrementKg: 2.5),
                ExerciseBlueprint(name: "Overhead Press", group: .shoulders, sets: 5, reps: 5, startKg: 20, incrementKg: 2.5),
                ExerciseBlueprint(name: "Deadlift", group: .back, sets: 1, reps: 5, startKg: 60, incrementKg: 5)
            ])
        ]
    )

    static let pushPullLegs = Blueprint(
        type: .pushPullLegs,
        name: "Push / Pull / Legs",
        summary: "A three-day rotation hitting pushing, pulling, and legs with compound + accessory work.",
        days: [
            DayBlueprint(name: "Push", exercises: [
                ExerciseBlueprint(name: "Bench Press", group: .chest, sets: 4, reps: 6, startKg: 40, incrementKg: 2.5),
                ExerciseBlueprint(name: "Overhead Press", group: .shoulders, sets: 3, reps: 8, startKg: 25, incrementKg: 2.5),
                ExerciseBlueprint(name: "Incline Dumbbell Press", group: .chest, sets: 3, reps: 10, startKg: 18, incrementKg: 1.25, isAccessory: true),
                ExerciseBlueprint(name: "Triceps Pushdown", group: .arms, sets: 3, reps: 12, startKg: 20, incrementKg: 1.25, isAccessory: true)
            ]),
            DayBlueprint(name: "Pull", exercises: [
                ExerciseBlueprint(name: "Deadlift", group: .back, sets: 3, reps: 5, startKg: 70, incrementKg: 5),
                ExerciseBlueprint(name: "Barbell Row", group: .back, sets: 4, reps: 8, startKg: 40, incrementKg: 2.5),
                ExerciseBlueprint(name: "Lat Pulldown", group: .back, sets: 3, reps: 10, startKg: 45, incrementKg: 2.5, isAccessory: true),
                ExerciseBlueprint(name: "Barbell Curl", group: .arms, sets: 3, reps: 12, startKg: 20, incrementKg: 1.25, isAccessory: true)
            ]),
            DayBlueprint(name: "Legs", exercises: [
                ExerciseBlueprint(name: "Squat", group: .legs, sets: 4, reps: 6, startKg: 50, incrementKg: 2.5),
                ExerciseBlueprint(name: "Romanian Deadlift", group: .legs, sets: 3, reps: 8, startKg: 45, incrementKg: 2.5),
                ExerciseBlueprint(name: "Leg Press", group: .legs, sets: 3, reps: 12, startKg: 80, incrementKg: 5, isAccessory: true),
                ExerciseBlueprint(name: "Hanging Leg Raise", group: .core, sets: 3, reps: 12, startKg: 0, incrementKg: 0, isAccessory: true)
            ])
        ]
    )

    static let upperLower = Blueprint(
        type: .upperLower,
        name: "Upper / Lower",
        summary: "Four sessions a week alternating upper- and lower-body strength work.",
        days: [
            DayBlueprint(name: "Upper", exercises: [
                ExerciseBlueprint(name: "Bench Press", group: .chest, sets: 4, reps: 6, startKg: 40, incrementKg: 2.5),
                ExerciseBlueprint(name: "Barbell Row", group: .back, sets: 4, reps: 6, startKg: 40, incrementKg: 2.5),
                ExerciseBlueprint(name: "Overhead Press", group: .shoulders, sets: 3, reps: 8, startKg: 25, incrementKg: 2.5),
                ExerciseBlueprint(name: "Barbell Curl", group: .arms, sets: 3, reps: 10, startKg: 20, incrementKg: 1.25, isAccessory: true)
            ]),
            DayBlueprint(name: "Lower", exercises: [
                ExerciseBlueprint(name: "Squat", group: .legs, sets: 4, reps: 6, startKg: 50, incrementKg: 2.5),
                ExerciseBlueprint(name: "Romanian Deadlift", group: .legs, sets: 3, reps: 8, startKg: 45, incrementKg: 2.5),
                ExerciseBlueprint(name: "Leg Press", group: .legs, sets: 3, reps: 10, startKg: 80, incrementKg: 5, isAccessory: true),
                ExerciseBlueprint(name: "Plank", group: .core, sets: 3, reps: 1, startKg: 0, incrementKg: 0, isAccessory: true)
            ])
        ]
    )

    static let fullBody3 = Blueprint(
        type: .fullBody3,
        name: "Full Body 3×",
        summary: "Three balanced full-body sessions per week — great for building a base.",
        days: [
            DayBlueprint(name: "Day 1", exercises: [
                ExerciseBlueprint(name: "Squat", group: .legs, sets: 3, reps: 5, startKg: 45, incrementKg: 2.5),
                ExerciseBlueprint(name: "Bench Press", group: .chest, sets: 3, reps: 5, startKg: 35, incrementKg: 2.5),
                ExerciseBlueprint(name: "Barbell Row", group: .back, sets: 3, reps: 5, startKg: 35, incrementKg: 2.5)
            ]),
            DayBlueprint(name: "Day 2", exercises: [
                ExerciseBlueprint(name: "Deadlift", group: .back, sets: 3, reps: 5, startKg: 60, incrementKg: 5),
                ExerciseBlueprint(name: "Overhead Press", group: .shoulders, sets: 3, reps: 5, startKg: 22.5, incrementKg: 2.5),
                ExerciseBlueprint(name: "Pull-up", group: .back, sets: 3, reps: 8, startKg: 0, incrementKg: 0, isAccessory: true)
            ]),
            DayBlueprint(name: "Day 3", exercises: [
                ExerciseBlueprint(name: "Front Squat", group: .legs, sets: 3, reps: 5, startKg: 40, incrementKg: 2.5),
                ExerciseBlueprint(name: "Incline Bench Press", group: .chest, sets: 3, reps: 6, startKg: 30, incrementKg: 2.5),
                ExerciseBlueprint(name: "Barbell Curl", group: .arms, sets: 3, reps: 10, startKg: 18, incrementKg: 1.25, isAccessory: true)
            ])
        ]
    )
}
