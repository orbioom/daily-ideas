import Foundation

struct WeekPoint: Identifiable {
    let weekStart: Date
    let value: Double
    var id: Date { weekStart }
}

struct MuscleSets: Identifiable {
    let muscle: Muscle
    let sets: Int
    var id: String { muscle.rawValue }
}

struct TrainingStats {
    let sessionCount: Int
    let totalTonnageKg: Double
    let avgDurationSeconds: Int
    let weeklyTonnage: [WeekPoint]
    let weeklySessions: [WeekPoint]
    let setsPerMuscle: [MuscleSets]
    let weekStreak: Int
    let thisWeekSessions: Int
}

/// Pure aggregation over logged sessions.
enum StatsEngine {

    static func compute(sessions: [WorkoutSession],
                        weeklyGoal: Int,
                        calendar: Calendar = .current,
                        now: Date = .now) -> TrainingStats {
        let completed = sessions.filter(\.completed)
        let count = completed.count
        let tonnage = completed.reduce(0) { $0 + $1.tonnageKg }
        let avgDur = count == 0 ? 0 : completed.reduce(0) { $0 + $1.durationSeconds } / count

        // Last 8 calendar weeks, oldest first.
        var weeklyT: [WeekPoint] = []
        var weeklyS: [WeekPoint] = []
        if let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start {
            for back in stride(from: 7, through: 0, by: -1) {
                guard let start = calendar.date(byAdding: .weekOfYear, value: -back, to: thisWeek),
                      let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { continue }
                let inWeek = completed.filter { $0.date >= start && $0.date < end }
                weeklyT.append(WeekPoint(weekStart: start, value: inWeek.reduce(0) { $0 + $1.tonnageKg }))
                weeklyS.append(WeekPoint(weekStart: start, value: Double(inWeek.count)))
            }
        }

        // Sets per muscle over the last 28 days.
        let cutoff = calendar.date(byAdding: .day, value: -28, to: now) ?? now
        var perMuscle: [Muscle: Int] = [:]
        for session in completed where session.date >= cutoff {
            for ex in session.exercises {
                perMuscle[ex.muscle, default: 0] += ex.sets.filter(\.done).count
            }
        }
        let muscleRows = Muscle.allCases.compactMap { m -> MuscleSets? in
            guard let s = perMuscle[m], s > 0 else { return nil }
            return MuscleSets(muscle: m, sets: s)
        }.sorted { $0.sets > $1.sets }

        // Week streak: consecutive weeks (ending with the latest fully-elapsed
        // or current week that meets the goal) with >= weeklyGoal sessions.
        var streak = 0
        let goal = max(1, weeklyGoal)
        let thisWeekCount = weeklyS.last.map { Int($0.value) } ?? 0
        var points = weeklyS
        if thisWeekCount < goal { points = Array(points.dropLast()) }  // current week still in progress
        for p in points.reversed() {
            if Int(p.value) >= goal { streak += 1 } else { break }
        }

        return TrainingStats(
            sessionCount: count,
            totalTonnageKg: tonnage,
            avgDurationSeconds: avgDur,
            weeklyTonnage: weeklyT,
            weeklySessions: weeklyS,
            setsPerMuscle: muscleRows,
            weekStreak: streak,
            thisWeekSessions: thisWeekCount
        )
    }
}
