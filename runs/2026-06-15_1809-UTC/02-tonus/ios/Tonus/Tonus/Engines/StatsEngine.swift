import Foundation

/// A single day's aggregated activity, used for charts and heatmaps.
struct DayStat: Identifiable, Hashable {
    var id: Date { day }
    let day: Date          // start-of-day
    let sessions: Int
    let reps: Int
    let minutes: Double
    let finished: Bool      // at least one finished session that day
}

/// Pure aggregation over SessionLogs. All divisions guarded.
struct StatsEngine {
    let logs: [SessionLog]
    let calendar: Calendar
    /// Reference "now" (injectable for determinism / testing).
    let now: Date

    init(logs: [SessionLog], now: Date = Date(), calendar: Calendar = .current) {
        // Newest first is convenient for recent lists.
        self.logs = logs.sorted { $0.date > $1.date }
        self.now = now
        self.calendar = calendar
    }

    private var finishedLogs: [SessionLog] { logs.filter { $0.finished } }

    // MARK: Totals

    var totalSessions: Int { finishedLogs.count }

    var totalReps: Int { finishedLogs.reduce(0) { $0 + $1.completedReps } }

    var totalMinutes: Double {
        finishedLogs.reduce(0.0) { $0 + $1.durationMinutes }
    }

    /// Whole minutes, rounded.
    var totalMinutesRounded: Int { Int(totalMinutes.rounded()) }

    // MARK: Streaks

    /// The set of distinct days (start-of-day) that have a finished session.
    private var finishedDays: Set<Date> {
        Set(finishedLogs.map { calendar.startOfDay(for: $0.date) })
    }

    /// Consecutive days up to (and including) today with a finished session.
    /// If today has none but yesterday does, the streak still counts (today is "in progress").
    var currentStreak: Int {
        let days = finishedDays
        guard !days.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)

        var cursor = today
        // Allow today to be empty without breaking a streak that ran through yesterday.
        if !days.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Longest run of consecutive finished days, ever.
    var bestStreak: Int {
        let sortedDays = finishedDays.sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<sortedDays.count {
            let prev = sortedDays[i - 1]
            let cur = sortedDays[i]
            if let next = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(next, inSameDayAs: cur) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    // MARK: This week

    /// Start of the current week per the user's calendar.
    var weekStart: Date {
        calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
    }

    var sessionsThisWeek: Int {
        finishedLogs.filter { $0.date >= weekStart }.count
    }

    var minutesThisWeek: Double {
        finishedLogs.filter { $0.date >= weekStart }.reduce(0.0) { $0 + $1.durationMinutes }
    }

    /// Adherence to a weekly goal, 0...1 (guarded against zero goal).
    func adherence(weeklyGoal: Int) -> Double {
        let goal = max(1, weeklyGoal)
        return min(1.0, Double(sessionsThisWeek) / Double(goal))
    }

    // MARK: Per-day series (for Charts)

    /// One DayStat per day for the last `days` days, oldest first. Empty days included as zeros.
    func dailySeries(days: Int) -> [DayStat] {
        let span = max(1, days)
        let today = calendar.startOfDay(for: now)

        // Bucket finished logs by start-of-day.
        var buckets: [Date: [SessionLog]] = [:]
        for log in finishedLogs {
            let key = calendar.startOfDay(for: log.date)
            buckets[key, default: []].append(log)
        }

        var series: [DayStat] = []
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayLogs = buckets[day] ?? []
            let reps = dayLogs.reduce(0) { $0 + $1.completedReps }
            let minutes = dayLogs.reduce(0.0) { $0 + $1.durationMinutes }
            series.append(DayStat(day: day,
                                  sessions: dayLogs.count,
                                  reps: reps,
                                  minutes: minutes,
                                  finished: !dayLogs.isEmpty))
        }
        return series
    }

    /// Recent finished + unfinished sessions, newest first, capped.
    func recent(limit: Int) -> [SessionLog] {
        Array(logs.prefix(max(0, limit)))
    }

    /// Logs visible to a free user: only those within `days` of now.
    func logsWithin(days: Int) -> [SessionLog] {
        let cutoff = calendar.date(byAdding: .day, value: -max(0, days), to: now) ?? now
        return logs.filter { $0.date >= cutoff }
    }
}
