import Foundation
import SwiftData

/// Seeds a realistic catalog and several weeks of training so charts and PRs
/// have something to show on first run.
enum SampleData {
    static func seed(into context: ModelContext) {
        let squat = Exercise(name: "Back Squat", group: .legs)
        let bench = Exercise(name: "Bench Press", group: .push)
        let dead = Exercise(name: "Deadlift", group: .pull)
        let ohp = Exercise(name: "Overhead Press", group: .push)
        let row = Exercise(name: "Barbell Row", group: .pull)
        let pull = Exercise(name: "Pull-up", group: .pull, isBodyweight: true)
        let catalog = [squat, bench, dead, ohp, row, pull]
        for e in catalog { context.insert(e) }

        let cal = Calendar.current
        // 8 sessions, every ~3 days, with gentle linear progression.
        let plan: [(String, [(Exercise, Double, Int, Int)])] = [
            ("Lower A", [(squat, 80, 5, 3), (dead, 100, 5, 1), (pull, 0, 8, 3)]),
            ("Upper A", [(bench, 60, 5, 3), (ohp, 40, 5, 3), (row, 55, 8, 3)]),
            ("Lower B", [(squat, 82.5, 5, 3), (dead, 102.5, 5, 1), (pull, 0, 9, 3)]),
            ("Upper B", [(bench, 62.5, 5, 3), (ohp, 41, 5, 3), (row, 57.5, 8, 3)]),
            ("Lower C", [(squat, 85, 5, 3), (dead, 105, 5, 1), (pull, 0, 10, 3)]),
            ("Upper C", [(bench, 65, 5, 3), (ohp, 42.5, 5, 3), (row, 60, 8, 3)]),
            ("Lower D", [(squat, 87.5, 4, 3), (dead, 110, 3, 1), (pull, 0, 11, 3)]),
            ("Upper D", [(bench, 67.5, 4, 3), (ohp, 44, 5, 3), (row, 62.5, 8, 3)]),
        ]
        for (i, session) in plan.enumerated() {
            let daysAgo = (plan.count - 1 - i) * 3
            let date = cal.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let w = Workout(date: date, title: session.0)
            context.insert(w)
            var order = 0
            for (ex, kg, reps, sets) in session.1 {
                // a light warm-up then working sets
                if kg > 0 {
                    let warm = SetEntry(exercise: ex, weightKg: kg * 0.6, reps: reps + 2, order: order)
                    warm.isWarmup = true; warm.workout = w; w.sets.append(warm); order += 1
                }
                for _ in 0..<sets {
                    let s = SetEntry(exercise: ex, weightKg: kg, reps: reps, order: order)
                    s.rpe = 8; s.workout = w; w.sets.append(s); order += 1
                }
            }
        }
        try? context.save()
    }
}
