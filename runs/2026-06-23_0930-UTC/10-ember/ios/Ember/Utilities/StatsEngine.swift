import Foundation

/// One bar in the "sessions per day/week" chart.
struct DayCount: Identifiable {
    let id: Date
    let date: Date
    let count: Int
    let minutes: Double
}

/// One point in the mood-trend chart (daily average across sessions + mood logs).
struct MoodPoint: Identifiable {
    let id: Date
    let date: Date
    let average: Double
}

/// One slice in the technique-usage breakdown.
struct StyleSlice: Identifiable {
    let id: String
    let style: BreathStyle
    let count: Int
}

/// Pure, testable computations over the user's sessions and mood entries.
/// Stateless — recreated cheaply from `@Query` results.
struct StatsEngine {
    let sessions: [BreathSession]
    let moods: [MoodEntry]
    var calendar: Calendar = .current
    var now: Date = .now

    // MARK: Totals

    var totalSessions: Int { sessions.count }

    var totalMinutes: Double { sessions.reduce(0) { $0 + $1.durationMinutes } }

    var averageSessionMinutes: Double {
        guard !sessions.isEmpty else { return 0 }
        return totalMinutes / Double(sessions.count)
    }

    var totalCycles: Int { sessions.reduce(0) { $0 + $1.cyclesCompleted } }

    // MARK: Streaks

    /// Set of calendar days (start-of-day) on which at least one session happened.
    private var activeDays: Set<Date> {
        Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
    }

    /// Consecutive-day streak ending today or yesterday.
    var currentStreak: Int {
        let days = activeDays
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = calendar.startOfDay(for: now)

        // Allow the streak to count if the most recent session was today OR yesterday.
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    var longestStreak: Int {
        let days = activeDays.sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<days.count {
            if let prev = calendar.date(byAdding: .day, value: 1, to: days[i - 1]),
               calendar.isDate(prev, inSameDayAs: days[i]) {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }

    // MARK: Charts

    /// Sessions and minutes per day for the last `days` days (oldest first).
    func dailyCounts(days: Int = 14) -> [DayCount] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { offset -> DayCount? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let same = sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            return DayCount(id: day, date: day,
                            count: same.count,
                            minutes: same.reduce(0) { $0 + $1.durationMinutes })
        }
    }

    /// Daily average mood from both session check-ins (post) and standalone logs.
    func moodTrend(days: Int = 14) -> [MoodPoint] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { offset -> MoodPoint? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            var values: [Double] = []
            for s in sessions where calendar.isDate(s.startedAt, inSameDayAs: day) {
                if s.moodAfter > 0 { values.append(Double(s.moodAfter)) }
            }
            for m in moods where calendar.isDate(m.date, inSameDayAs: day) {
                values.append(Double(m.score))
            }
            let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
            return MoodPoint(id: day, date: day, average: avg)
        }
    }

    /// Technique usage breakdown (descending by count).
    var styleBreakdown: [StyleSlice] {
        var counts: [BreathStyle: Int] = [:]
        for s in sessions { counts[s.style, default: 0] += 1 }
        return counts
            .map { StyleSlice(id: $0.key.rawValue, style: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    /// Average mood improvement (after − before) across sessions that recorded both.
    var averageMoodLift: Double? {
        let deltas = sessions.compactMap { $0.moodDelta }
        guard !deltas.isEmpty else { return nil }
        return Double(deltas.reduce(0, +)) / Double(deltas.count)
    }

    var sessionsThisWeek: Int {
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }
        return sessions.filter { $0.startedAt >= weekAgo }.count
    }
}
