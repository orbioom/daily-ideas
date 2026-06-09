import Foundation

/// Pure functions over a session history: streaks, totals, and chartable series.
/// Kept separate from views so the logic is testable and deterministic.
enum StatsEngine {

    struct DailyPoint: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Int
        let sits: Int
    }

    struct Summary {
        var totalSessions: Int = 0
        var totalMinutes: Int = 0
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var completionRate: Double = 0   // 0…1
        var avgMinutes: Int = 0
        var thisWeekMinutes: Int = 0
    }

    static func summary(_ sessions: [MeditationSession],
                        calendar: Calendar = .current,
                        now: Date = .now) -> Summary {
        var s = Summary()
        guard !sessions.isEmpty else { return s }

        s.totalSessions = sessions.count
        s.totalMinutes = sessions.reduce(0) { $0 + $1.minutes }
        let completed = sessions.filter { $0.completed }.count
        s.completionRate = Double(completed) / Double(sessions.count)
        s.avgMinutes = Int((Double(s.totalMinutes) / Double(sessions.count)).rounded())

        // Distinct meditated days
        let days = Set(sessions.map { calendar.startOfDay(for: $0.date) }).sorted()
        s.longestStreak = longestRun(of: days, calendar: calendar)
        s.currentStreak = currentRun(of: Set(days), calendar: calendar, now: now)

        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start {
            s.thisWeekMinutes = sessions
                .filter { $0.date >= weekStart }
                .reduce(0) { $0 + $1.minutes }
        }
        return s
    }

    private static func longestRun(of days: [Date], calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        var longest = 1
        var run = 1
        for i in 1..<days.count {
            if let next = calendar.date(byAdding: .day, value: 1, to: days[i - 1]),
               calendar.isDate(next, inSameDayAs: days[i]) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }

    private static func currentRun(of days: Set<Date>, calendar: Calendar, now: Date) -> Int {
        let today = calendar.startOfDay(for: now)
        // A streak is "current" if the user sat today or yesterday.
        var anchor = today
        if !days.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) else { return 0 }
            anchor = yesterday
        }
        var count = 0
        var cursor = anchor
        while days.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    /// Minutes per day for the last `days` days (oldest → newest), zero-filled.
    static func dailySeries(_ sessions: [MeditationSession],
                            days: Int,
                            calendar: Calendar = .current,
                            now: Date = .now) -> [DailyPoint] {
        let today = calendar.startOfDay(for: now)
        var byDay: [Date: (min: Int, sits: Int)] = [:]
        for s in sessions {
            let d = calendar.startOfDay(for: s.date)
            let cur = byDay[d] ?? (0, 0)
            byDay[d] = (cur.min + s.minutes, cur.sits + 1)
        }
        var out: [DailyPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let d = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let v = byDay[d] ?? (0, 0)
            out.append(DailyPoint(date: d, minutes: v.min, sits: v.sits))
        }
        return out
    }

    /// Total minutes grouped by preset name, descending.
    static func minutesByPreset(_ sessions: [MeditationSession]) -> [(name: String, minutes: Int)] {
        var dict: [String: Int] = [:]
        for s in sessions { dict[s.presetName, default: 0] += s.minutes }
        return dict.map { (name: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }
    }
}
