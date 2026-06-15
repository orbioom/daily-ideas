import Foundation

/// One day's aggregated activity, used for charts and the dashboard.
struct DayStat: Identifiable, Hashable {
    let id: Date          // start of day
    let date: Date
    let breaks: Int
    let exerciseMinutes: Double
}

/// Pure aggregation over logged breaks and exercise sessions.
/// Every division is guarded; never crashes on empty input.
struct StatsEngine {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    // MARK: - Today

    func breaksToday(_ logs: [BreakLog], now: Date = .now) -> Int {
        let today = startOfDay(now)
        return logs.filter { $0.completed && startOfDay($0.date) == today }.count
    }

    func exerciseMinutesToday(_ sessions: [ExerciseSession], now: Date = .now) -> Double {
        let today = startOfDay(now)
        return sessions
            .filter { startOfDay($0.date) == today }
            .reduce(0) { $0 + $1.minutes }
    }

    func mostRecentBreak(_ logs: [BreakLog]) -> Date? {
        logs.filter { $0.completed }.map(\.date).max()
    }

    // MARK: - Totals

    func totalBreaks(_ logs: [BreakLog]) -> Int {
        logs.filter { $0.completed }.count
    }

    func totalExerciseMinutes(_ sessions: [ExerciseSession]) -> Double {
        sessions.reduce(0) { $0 + $1.minutes }
    }

    // MARK: - Streak

    /// Count of consecutive days (ending today or yesterday) with at least one completed break.
    func currentStreak(_ logs: [BreakLog], now: Date = .now) -> Int {
        let activeDays = Set(logs.filter { $0.completed }.map { startOfDay($0.date) })
        guard !activeDays.isEmpty else { return 0 }

        let today = startOfDay(now)
        // Allow the streak to count even if today has no break yet (anchor on yesterday).
        var cursor: Date
        if activeDays.contains(today) {
            cursor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  activeDays.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while activeDays.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    // MARK: - Daily series (for Charts)

    /// A series of the last `days` calendar days (oldest first), each with breaks + minutes.
    func dailySeries(logs: [BreakLog], sessions: [ExerciseSession], days: Int, now: Date = .now) -> [DayStat] {
        let span = max(1, days)
        let today = startOfDay(now)

        // Pre-bucket for O(n) aggregation.
        var breaksByDay: [Date: Int] = [:]
        for log in logs where log.completed {
            let d = startOfDay(log.date)
            breaksByDay[d, default: 0] += 1
        }
        var minutesByDay: [Date: Double] = [:]
        for s in sessions {
            let d = startOfDay(s.date)
            minutesByDay[d, default: 0] += s.minutes
        }

        var result: [DayStat] = []
        result.reserveCapacity(span)
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            result.append(DayStat(id: day,
                                  date: day,
                                  breaks: breaksByDay[day] ?? 0,
                                  exerciseMinutes: minutesByDay[day] ?? 0))
        }
        return result
    }

    // MARK: - Adherence

    /// Average daily breaks over the window vs the goal, clamped 0...1.
    func adherence(logs: [BreakLog], dailyGoal: Int, days: Int, now: Date = .now) -> Double {
        let span = max(1, days)
        let goal = max(1, dailyGoal)
        let series = dailySeries(logs: logs, sessions: [], days: span, now: now)
        guard !series.isEmpty else { return 0 }
        let avgPerDay = Double(series.reduce(0) { $0 + $1.breaks }) / Double(series.count)
        return min(1, max(0, avgPerDay / Double(goal)))
    }

    /// Number of days in the window where the goal was met.
    func daysGoalMet(logs: [BreakLog], dailyGoal: Int, days: Int, now: Date = .now) -> Int {
        let goal = max(1, dailyGoal)
        return dailySeries(logs: logs, sessions: [], days: days, now: now)
            .filter { $0.breaks >= goal }
            .count
    }
}
