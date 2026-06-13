import Foundation

/// Computes a runner's position in a plan from their logged sessions.
struct PlanProgress {
    let plan: RunPlan
    let logs: [RunLog]      // logs belonging to this plan

    private var doneKeys: Set<String> {
        Set(logs.map { "\($0.weekNumber)-\($0.sessionIndex)" })
    }

    func isComplete(week: Int, session: Int) -> Bool {
        doneKeys.contains("\(week)-\(session)")
    }

    func weekCompleted(_ week: WeekPlan) -> Int {
        (0..<week.sessions.count).filter { isComplete(week: week.number, session: $0) }.count
    }

    var completedSessions: Int { doneKeys.count }

    var fractionComplete: Double {
        guard plan.totalSessions > 0 else { return 0 }
        return min(1, Double(completedSessions) / Double(plan.totalSessions))
    }

    /// The next session to run, or nil if the plan is finished.
    var current: (week: WeekPlan, session: Int)? {
        for week in plan.weeks {
            for s in 0..<week.sessions.count where !isComplete(week: week.number, session: s) {
                return (week, s)
            }
        }
        return nil
    }

    var isFinished: Bool { current == nil }

    /// Consecutive-day streak of running, counting back from the most recent run.
    var streakDays: Int {
        let cal = Calendar.current
        let days = Set(logs.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        guard let first = days.first else { return 0 }
        // Streak only counts if the last run was today or yesterday.
        let today = cal.startOfDay(for: .now)
        let gap = cal.dateComponents([.day], from: first, to: today).day ?? 99
        guard gap <= 1 else { return 0 }
        var streak = 1
        var prev = first
        for day in days.dropFirst() {
            let d = cal.dateComponents([.day], from: day, to: prev).day ?? 99
            if d == 1 { streak += 1; prev = day } else { break }
        }
        return streak
    }
}
