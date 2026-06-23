import Foundation
import SwiftData

/// Seeds the exercise library, starter routines, and a realistic training history.
enum SeedData {
    /// Library of 44 compound & accessory lifts with muscle group + equipment.
    static let library: [(String, MuscleGroup, Equipment)] = [
        // Chest
        ("Barbell Bench Press", .chest, .barbell),
        ("Incline Barbell Press", .chest, .barbell),
        ("Dumbbell Bench Press", .chest, .dumbbell),
        ("Incline Dumbbell Press", .chest, .dumbbell),
        ("Cable Chest Fly", .chest, .cable),
        ("Push-Up", .chest, .bodyweight),
        ("Machine Chest Press", .chest, .machine),
        // Back
        ("Deadlift", .back, .barbell),
        ("Barbell Row", .back, .barbell),
        ("Pull-Up", .back, .bodyweight),
        ("Lat Pulldown", .back, .cable),
        ("Seated Cable Row", .back, .cable),
        ("Dumbbell Row", .back, .dumbbell),
        ("T-Bar Row", .back, .machine),
        // Shoulders
        ("Overhead Press", .shoulders, .barbell),
        ("Seated Dumbbell Press", .shoulders, .dumbbell),
        ("Lateral Raise", .shoulders, .dumbbell),
        ("Cable Lateral Raise", .shoulders, .cable),
        ("Rear Delt Fly", .shoulders, .dumbbell),
        ("Face Pull", .shoulders, .cable),
        // Quads / Legs
        ("Back Squat", .quads, .barbell),
        ("Front Squat", .quads, .barbell),
        ("Leg Press", .quads, .machine),
        ("Bulgarian Split Squat", .quads, .dumbbell),
        ("Leg Extension", .quads, .machine),
        ("Goblet Squat", .quads, .kettlebell),
        // Hamstrings / Glutes
        ("Romanian Deadlift", .hamstrings, .barbell),
        ("Lying Leg Curl", .hamstrings, .machine),
        ("Hip Thrust", .glutes, .barbell),
        ("Glute Bridge", .glutes, .bodyweight),
        ("Cable Pull-Through", .glutes, .cable),
        // Biceps
        ("Barbell Curl", .biceps, .barbell),
        ("Dumbbell Curl", .biceps, .dumbbell),
        ("Hammer Curl", .biceps, .dumbbell),
        ("Cable Curl", .biceps, .cable),
        // Triceps
        ("Close-Grip Bench Press", .triceps, .barbell),
        ("Triceps Pushdown", .triceps, .cable),
        ("Overhead Triceps Extension", .triceps, .dumbbell),
        ("Dip", .triceps, .bodyweight),
        // Core
        ("Hanging Leg Raise", .core, .bodyweight),
        ("Cable Crunch", .core, .cable),
        ("Plank", .core, .bodyweight),
        // Calves / Forearms
        ("Standing Calf Raise", .calves, .machine),
        ("Farmer's Carry", .forearms, .dumbbell),
    ]

    /// Starter routine templates: name, detail, color, and (exerciseName, sets, reps).
    static let routineTemplates: [(String, String, String, [(String, Int, Int)])] = [
        ("Push Day", "Chest · Shoulders · Triceps", "#EA7320", [
            ("Barbell Bench Press", 4, 6),
            ("Overhead Press", 3, 8),
            ("Incline Dumbbell Press", 3, 10),
            ("Lateral Raise", 3, 15),
            ("Triceps Pushdown", 3, 12),
        ]),
        ("Pull Day", "Back · Biceps", "#7C5CC6", [
            ("Deadlift", 3, 5),
            ("Pull-Up", 4, 8),
            ("Barbell Row", 3, 8),
            ("Seated Cable Row", 3, 12),
            ("Barbell Curl", 3, 10),
        ]),
        ("Leg Day", "Quads · Hamstrings · Glutes", "#289A60", [
            ("Back Squat", 4, 6),
            ("Romanian Deadlift", 3, 8),
            ("Leg Press", 3, 12),
            ("Lying Leg Curl", 3, 12),
            ("Standing Calf Raise", 4, 15),
        ]),
        ("Upper Body", "Full upper session", "#2E79D5", [
            ("Barbell Bench Press", 4, 6),
            ("Barbell Row", 4, 8),
            ("Seated Dumbbell Press", 3, 10),
            ("Lat Pulldown", 3, 12),
            ("Hammer Curl", 3, 12),
        ]),
        ("Full Body", "Big-three foundation", "#E25850", [
            ("Back Squat", 3, 5),
            ("Barbell Bench Press", 3, 5),
            ("Barbell Row", 3, 8),
            ("Overhead Press", 3, 8),
        ]),
    ]

    static func seedIfNeeded(_ context: ModelContext) {
        seedSettings(context)
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        if existing.isEmpty {
            let byName = seedExercises(context)
            seedRoutines(context, byName: byName)
            seedHistory(context, byName: byName)
            try? context.save()
        }
    }

    static func seedSettings(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<AppSettings>())) ?? []
        if existing.isEmpty {
            context.insert(AppSettings())
            try? context.save()
        }
    }

    @discardableResult
    private static func seedExercises(_ context: ModelContext) -> [String: Exercise] {
        var byName: [String: Exercise] = [:]
        // A few sensible defaults marked favorite.
        let favorites: Set<String> = ["Barbell Bench Press", "Back Squat", "Deadlift", "Overhead Press", "Pull-Up"]
        for (name, muscle, equip) in library {
            let ex = Exercise(name: name, muscle: muscle, equipment: equip, isFavorite: favorites.contains(name))
            context.insert(ex)
            byName[name] = ex
        }
        return byName
    }

    private static func seedRoutines(_ context: ModelContext, byName: [String: Exercise]) {
        for (name, detail, color, items) in routineTemplates {
            let routine = Routine(name: name, detail: detail, colorHex: color, isBuiltIn: true)
            context.insert(routine)
            for (idx, item) in items.enumerated() {
                guard let ex = byName[item.0] else { continue }
                let ri = RoutineItem(order: idx, targetSets: item.1, targetReps: item.2, routine: routine, exercise: ex)
                context.insert(ri)
                routine.items.append(ri)
            }
        }
    }

    /// Builds ~9 weeks of progressive history across Push/Pull/Leg sessions so
    /// charts, PRs, and history all have realistic data (well over 50 sets).
    private static func seedHistory(_ context: ModelContext, byName: [String: Exercise]) {
        struct Plan { let title: String; let lifts: [(String, Double, Int, Int)] } // name, startKg, sets, reps
        let plans: [Plan] = [
            Plan(title: "Push Day", lifts: [
                ("Barbell Bench Press", 70, 4, 6),
                ("Overhead Press", 42, 3, 8),
                ("Incline Dumbbell Press", 24, 3, 10),
                ("Lateral Raise", 10, 3, 15),
                ("Triceps Pushdown", 25, 3, 12),
            ]),
            Plan(title: "Pull Day", lifts: [
                ("Deadlift", 120, 3, 5),
                ("Barbell Row", 60, 3, 8),
                ("Lat Pulldown", 55, 3, 12),
                ("Seated Cable Row", 50, 3, 12),
                ("Barbell Curl", 30, 3, 10),
            ]),
            Plan(title: "Leg Day", lifts: [
                ("Back Squat", 90, 4, 6),
                ("Romanian Deadlift", 80, 3, 8),
                ("Leg Press", 140, 3, 12),
                ("Lying Leg Curl", 40, 3, 12),
                ("Standing Calf Raise", 60, 4, 15),
            ]),
        ]

        let cal = Calendar.current
        let now = Date()
        var session = 0
        // 9 weeks back to now, 3 sessions/week.
        for week in stride(from: 9, through: 1, by: -1) {
            for (dayOffset, plan) in zip([0, 2, 4], plans) {
                guard let day = cal.date(byAdding: .day, value: -(week * 7) + dayOffset, to: now) else { continue }
                let started = cal.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
                let progression = Double(9 - week) // 0...8 weeks of progress
                let workout = Workout(title: plan.title, startedAt: started,
                                      finishedAt: started.addingTimeInterval(Double.random(in: 2900...4200)))
                context.insert(workout)
                var order = 0
                for (name, startKg, sets, reps) in plan.lifts {
                    guard let ex = byName[name] else { continue }
                    // Linear-ish progression with a little noise.
                    let step = (startKg * 0.02)
                    let weight = (startKg + step * progression).rounded()
                    for s in 0..<sets {
                        let isWarm = s == 0 && startKg >= 60
                        let w = isWarm ? (weight * 0.55).rounded() : weight
                        let r = isWarm ? reps + 2 : reps
                        let entry = SetEntry(
                            order: order,
                            weightKg: max(0, w),
                            reps: r,
                            rpe: isWarm ? nil : Double(Int.random(in: 7...9)),
                            isWarmup: isWarm,
                            isCompleted: true,
                            loggedAt: started.addingTimeInterval(Double(order) * 150),
                            workout: workout,
                            exercise: ex
                        )
                        context.insert(entry)
                        workout.sets.append(entry)
                        order += 1
                    }
                }
                session += 1
            }
        }
    }
}
