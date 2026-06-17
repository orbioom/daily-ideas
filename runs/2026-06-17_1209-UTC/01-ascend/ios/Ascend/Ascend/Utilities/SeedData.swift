import Foundation
import SwiftData

/// Seeds an active StrongLifts 5×5 program plus a realistic block of past sessions,
/// so History and Progress look alive on first launch. Idempotent via a count check.
enum SeedData {

    static func seedIfNeeded(context: ModelContext) {
        // Idempotent: only seed when there are no programs at all.
        let programCount = (try? context.fetchCount(FetchDescriptor<Program>())) ?? 0
        guard programCount == 0 else { return }

        let program = BuiltInPrograms.makeProgram(from: BuiltInPrograms.strongLifts5x5, isActive: true)
        context.insert(program)
        seedHistory(context: context)
        try? context.save()
    }

    /// Wipe everything (used by Settings "clear" / re-seed).
    static func clearAll(context: ModelContext) {
        for program in (try? context.fetch(FetchDescriptor<Program>())) ?? [] {
            context.delete(program)
        }
        for session in (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? [] {
            context.delete(session)
        }
        try? context.save()
    }

    /// Re-seed sample data even if some exists (Settings → Load sample data).
    static func reseed(context: ModelContext) {
        clearAll(context: context)
        let program = BuiltInPrograms.makeProgram(from: BuiltInPrograms.strongLifts5x5, isActive: true)
        context.insert(program)
        seedHistory(context: context)
        try? context.save()
    }

    // MARK: Past sessions

    private struct LiftPlan {
        let name: String
        let group: MuscleGroup
        let sets: Int
        let reps: Int
        let startKg: Double
        let stepKg: Double
    }

    private static func seedHistory(context: ModelContext) {
        // Alternating A/B StrongLifts days. Squat appears in both, progressing every session.
        let workoutA: [LiftPlan] = [
            LiftPlan(name: "Squat", group: .legs, sets: 5, reps: 5, startKg: 40, stepKg: 2.5),
            LiftPlan(name: "Bench Press", group: .chest, sets: 5, reps: 5, startKg: 30, stepKg: 2.5),
            LiftPlan(name: "Barbell Row", group: .back, sets: 5, reps: 5, startKg: 30, stepKg: 2.5)
        ]
        let workoutB: [LiftPlan] = [
            LiftPlan(name: "Squat", group: .legs, sets: 5, reps: 5, startKg: 40, stepKg: 2.5),
            LiftPlan(name: "Overhead Press", group: .shoulders, sets: 5, reps: 5, startKg: 20, stepKg: 2.5),
            LiftPlan(name: "Deadlift", group: .back, sets: 1, reps: 5, startKg: 60, stepKg: 5)
        ]

        // Track how many sessions each lift has appeared in, for linear progression.
        var occurrences: [String: Int] = [:]
        let calendar = Calendar.current
        let totalSessions = 12

        for i in 0..<totalSessions {
            let isA = i % 2 == 0
            let plans = isA ? workoutA : workoutB
            let dayName = isA ? "Workout A" : "Workout B"
            // Sessions every ~3 days, oldest first. Most recent ~3 days ago.
            let daysAgo = (totalSessions - i) * 3
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            let session = WorkoutSession(date: date,
                                         programName: "StrongLifts 5×5",
                                         dayName: dayName,
                                         durationSeconds: 2400 + (i % 4) * 240,
                                         notes: "",
                                         isComplete: true)

            for (order, plan) in plans.enumerated() {
                let n = occurrences[plan.name, default: 0]
                occurrences[plan.name] = n + 1
                let weight = plan.startKg + Double(n) * plan.stepKg

                let logged = LoggedExercise(name: plan.name, muscleGroup: plan.group.rawValue, order: order)
                logged.session = session

                // One warmup set on the main compound lifts.
                if plan.sets >= 5 && weight >= 40 {
                    let warm = LoggedSet(setIndex: 0,
                                         weightKg: Units.roundToPlate(weight * 0.5, step: 2.5),
                                         reps: 5,
                                         isWarmup: true,
                                         isComplete: true)
                    warm.exercise = logged
                    logged.sets.append(warm)
                }

                // A couple of recent heavy sessions show a missed rep (realistic grind).
                let nearTop = i >= totalSessions - 3
                for s in 0..<plan.sets {
                    let missed = nearTop && plan.name == "Bench Press" && s == plan.sets - 1
                    let set = LoggedSet(setIndex: logged.sets.count,
                                        weightKg: weight,
                                        reps: missed ? plan.reps - 1 : plan.reps,
                                        isWarmup: false,
                                        isComplete: true)
                    set.exercise = logged
                    logged.sets.append(set)
                }

                session.exercises.append(logged)
            }
            context.insert(session)
        }
    }
}
