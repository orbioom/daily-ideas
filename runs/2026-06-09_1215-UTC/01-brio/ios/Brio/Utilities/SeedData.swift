import Foundation
import SwiftData

/// Seeds the exercise library, a handful of built-in workouts, and a realistic
/// stretch of history on first launch so charts, streaks, and lists are never
/// empty for a brand-new user. Guarded so it runs at most once.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let library = seedExercises(context)
        seedWorkouts(context, library: library)
        seedHistory(context)

        try? context.save()
    }

    // MARK: - Exercises

    private static func seedExercises(_ context: ModelContext) -> [String: Exercise] {
        let defs: [Exercise] = [
            Exercise(name: "Push-ups", detail: "Lower your chest to the floor with elbows tucked, then press back up keeping a straight line from head to heels.",
                     muscleGroup: .upper, kind: .reps, defaultReps: 12, symbol: "figure.strengthtraining.functional", isBuiltIn: true),
            Exercise(name: "Squats", detail: "Sit your hips back and down until your thighs are parallel, then drive through your heels to stand.",
                     muscleGroup: .lower, kind: .reps, defaultReps: 15, symbol: "figure.step.training", isBuiltIn: true),
            Exercise(name: "Plank", detail: "Hold a straight line on your forearms and toes, bracing your core and glutes without letting your hips sag.",
                     muscleGroup: .core, kind: .timed, defaultDurationSec: 40, symbol: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Lunges", detail: "Step forward and lower until both knees bend to ninety degrees, then push back to standing.",
                     muscleGroup: .lower, kind: .reps, defaultReps: 10, symbol: "figure.step.training", isBuiltIn: true),
            Exercise(name: "Mountain climbers", detail: "From a plank, drive your knees toward your chest one at a time at a steady, quick pace.",
                     muscleGroup: .cardio, kind: .timed, defaultDurationSec: 30, symbol: "figure.run", isBuiltIn: true),
            Exercise(name: "Burpees", detail: "Drop to a push-up, jump your feet back in, then explode upward into a jump with arms overhead.",
                     muscleGroup: .fullBody, kind: .reps, defaultReps: 10, symbol: "figure.mixed.cardio", isBuiltIn: true),
            Exercise(name: "Glute bridge", detail: "Lying on your back, drive through your heels to lift your hips until your body forms a straight line.",
                     muscleGroup: .lower, kind: .reps, defaultReps: 15, symbol: "figure.core.training", isBuiltIn: true),
            Exercise(name: "High knees", detail: "Run in place driving your knees up to hip height, staying light and quick on the balls of your feet.",
                     muscleGroup: .cardio, kind: .timed, defaultDurationSec: 30, symbol: "figure.run", isBuiltIn: true),
            Exercise(name: "Bicycle crunches", detail: "Bring opposite elbow to knee in a pedaling motion, rotating through your core with control.",
                     muscleGroup: .core, kind: .reps, defaultReps: 20, symbol: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Superman", detail: "Lying face down, lift your arms, chest, and legs off the floor and hold, squeezing your lower back and glutes.",
                     muscleGroup: .core, kind: .timed, defaultDurationSec: 25, symbol: "figure.flexibility", isBuiltIn: true),
            Exercise(name: "Jumping jacks", detail: "Jump your feet out while raising your arms overhead, then jump back to standing in a steady rhythm.",
                     muscleGroup: .cardio, kind: .timed, defaultDurationSec: 40, symbol: "figure.mixed.cardio", isBuiltIn: true),
            Exercise(name: "Dead bug", detail: "On your back, extend the opposite arm and leg while keeping your low back pressed into the floor.",
                     muscleGroup: .core, kind: .reps, defaultReps: 12, symbol: "figure.core.training", isBuiltIn: true),
            Exercise(name: "Wall sit", detail: "Slide down a wall until your thighs are parallel to the floor and hold, keeping your back flat against it.",
                     muscleGroup: .lower, kind: .timed, defaultDurationSec: 45, symbol: "figure.step.training", isBuiltIn: true),
            Exercise(name: "Calf raises", detail: "Rise onto the balls of your feet as high as you can, pause, then lower under control.",
                     muscleGroup: .lower, kind: .reps, defaultReps: 20, symbol: "figure.step.training", isBuiltIn: true),
            Exercise(name: "Bird dog", detail: "On all fours, extend the opposite arm and leg until level, hold briefly, then return with control.",
                     muscleGroup: .core, kind: .reps, defaultReps: 10, symbol: "figure.flexibility", isBuiltIn: true),
            Exercise(name: "Side plank", detail: "Stack your feet and prop on one forearm, lifting your hips so your body forms a straight diagonal line.",
                     muscleGroup: .core, kind: .timed, defaultDurationSec: 25, symbol: "figure.core.training", isBuiltIn: true)
        ]
        // Per-side defaults for moves that naturally alternate sides.
        var byName: [String: Exercise] = [:]
        for e in defs {
            context.insert(e)
            byName[e.name] = e
        }
        return byName
    }

    // MARK: - Workouts

    private static func seedWorkouts(_ context: ModelContext, library: [String: Exercise]) {
        func item(_ name: String, order: Int, perSide: Bool = false,
                  reps: Int? = nil, dur: Int? = nil) -> WorkoutItem? {
            guard let ex = library[name] else { return nil }
            let it = WorkoutItem(from: ex, order: order)
            it.perSide = perSide
            if let reps { it.reps = reps }
            if let dur { it.durationSec = dur }
            return it
        }

        struct WDef {
            let name: String
            let summary: String
            let category: WorkoutCategory
            let difficulty: Difficulty
            let rounds: Int
            let restEx: Int
            let restRound: Int
            let items: [(String, Bool, Int?, Int?)]   // name, perSide, reps, dur
        }

        let defs: [WDef] = [
            WDef(name: "Morning Spark", summary: "A quick full-body wake-up to start the day moving.",
                 category: .fullBody, difficulty: .easy, rounds: 2, restEx: 15, restRound: 45,
                 items: [("Jumping jacks", false, nil, 40), ("Squats", false, 15, nil),
                         ("Push-ups", false, 10, nil), ("Plank", false, nil, 30)]),
            WDef(name: "Core Crusher", summary: "Targeted core circuit to build a stable, strong midsection.",
                 category: .core, difficulty: .moderate, rounds: 3, restEx: 15, restRound: 60,
                 items: [("Bicycle crunches", false, 20, nil), ("Plank", false, nil, 40),
                         ("Dead bug", false, 12, nil), ("Side plank", true, nil, 25),
                         ("Superman", false, nil, 25)]),
            WDef(name: "Lower Burn", summary: "Legs and glutes — no equipment, all effort.",
                 category: .lowerBody, difficulty: .moderate, rounds: 3, restEx: 20, restRound: 60,
                 items: [("Squats", false, 20, nil), ("Lunges", true, 10, nil),
                         ("Glute bridge", false, 15, nil), ("Wall sit", false, nil, 45),
                         ("Calf raises", false, 20, nil)]),
            WDef(name: "Upper Push", summary: "Build pressing strength with bodyweight basics.",
                 category: .upperBody, difficulty: .hard, rounds: 4, restEx: 20, restRound: 75,
                 items: [("Push-ups", false, 12, nil), ("Plank", false, nil, 40),
                         ("Bird dog", true, 10, nil)]),
            WDef(name: "HIIT Sprint", summary: "Fast, sweaty intervals to spike your heart rate.",
                 category: .cardio, difficulty: .hard, rounds: 4, restEx: 15, restRound: 45,
                 items: [("High knees", false, nil, 30), ("Burpees", false, 10, nil),
                         ("Mountain climbers", false, nil, 30), ("Jumping jacks", false, nil, 40)]),
            WDef(name: "Reset & Stretch", summary: "Gentle mobility to loosen up and recover.",
                 category: .mobility, difficulty: .easy, rounds: 2, restEx: 10, restRound: 40,
                 items: [("Bird dog", true, 10, nil), ("Superman", false, nil, 25),
                         ("Glute bridge", false, 15, nil), ("Side plank", true, nil, 20)])
        ]

        for (idx, d) in defs.enumerated() {
            let items = d.items.enumerated().compactMap { (i, spec) in
                item(spec.0, order: i, perSide: spec.1, reps: spec.2, dur: spec.3)
            }
            let workout = Workout(name: d.name, summary: d.summary, category: d.category,
                                  difficulty: d.difficulty, rounds: d.rounds,
                                  restBetweenExercisesSec: d.restEx,
                                  restBetweenRoundsSec: d.restRound,
                                  isBuiltIn: true, sortIndex: idx, items: items)
            context.insert(workout)
        }
    }

    // MARK: - History

    private static func seedHistory(_ context: ModelContext) {
        let cal = Calendar.current
        let names: [(String, WorkoutCategory)] = [
            ("Morning Spark", .fullBody), ("Core Crusher", .core), ("Lower Burn", .lowerBody),
            ("Upper Push", .upperBody), ("HIIT Sprint", .cardio), ("Reset & Stretch", .mobility)
        ]
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func rnd() -> Double {
            // Deterministic xorshift so seeded history is stable across launches.
            seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
            return Double(seed % 10_000) / 10_000.0
        }

        var inserted = 0
        // Walk back 56 days; on ~most days insert a session, sometimes two.
        for dayOffset in 0..<56 {
            guard inserted < 52 else { break }
            // ~70% of days have a session.
            if rnd() > 0.70 { continue }
            let count = rnd() > 0.85 ? 2 : 1
            for _ in 0..<count {
                guard inserted < 52 else { break }
                let pick = names[Int(rnd() * Double(names.count)) % names.count]
                let minutes = 8 + Int(rnd() * 27)        // 8…35 min
                let planned = minutes * 60
                let completed = rnd() > 0.18              // mostly completed
                let actual = completed ? planned : Int(Double(planned) * (0.4 + rnd() * 0.4))
                let feeling = rnd() > 0.4 ? 1 + Int(rnd() * 5) : 0   // some unrated
                let hour = 6 + Int(rnd() * 14)
                if let base = cal.date(byAdding: .day, value: -dayOffset, to: .now),
                   let date = cal.date(bySettingHour: min(hour, 22), minute: Int(rnd() * 59),
                                       second: 0, of: base) {
                    let rounds = completed ? (2 + Int(rnd() * 3)) : (1 + Int(rnd() * 2))
                    context.insert(WorkoutSession(date: date, workoutName: pick.0,
                                                  category: pick.1, plannedSeconds: planned,
                                                  actualSeconds: actual, roundsCompleted: rounds,
                                                  completed: completed,
                                                  feeling: min(feeling, 5)))
                    inserted += 1
                }
            }
        }
    }
}
