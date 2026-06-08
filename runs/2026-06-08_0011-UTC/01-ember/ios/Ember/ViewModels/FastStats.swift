import Foundation

/// Derived statistics over a collection of completed fasts.
struct FastStats {
    let total: Int
    let completed: Int
    let goalsHit: Int
    let averageHours: Double
    let longestHours: Double
    let totalHours: Double
    let currentStreakDays: Int
    let last7: [DayBar]

    struct DayBar: Identifiable {
        let id = UUID()
        let date: Date
        let hours: Double
        let hitGoal: Bool
    }

    var completionRate: Double {
        guard completed > 0 else { return 0 }
        return Double(goalsHit) / Double(completed)
    }

    static func make(from fasts: [Fast], calendar: Calendar = .current, now: Date = .now) -> FastStats {
        let finished = fasts.filter { $0.end != nil }
        let durations = finished.map { $0.elapsedSeconds / 3600 }
        let avg = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
        let longest = durations.max() ?? 0
        let totalH = durations.reduce(0, +)
        let goalsHit = finished.filter { $0.didReachGoal }.count

        // Streak: consecutive days (counting back from today) that have at least
        // one completed fast.
        var streak = 0
        var day = calendar.startOfDay(for: now)
        let daysWithFast = Set(finished.compactMap { fast -> Date? in
            guard let end = fast.end else { return nil }
            return calendar.startOfDay(for: end)
        })
        // Allow today to be missing (fast may be in progress) without breaking.
        if !daysWithFast.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while daysWithFast.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        // Last 7 days bars (best fast per day).
        var bars: [DayBar] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let d = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now)) else { continue }
            let dayFasts = finished.filter {
                guard let end = $0.end else { return false }
                return calendar.isDate(end, inSameDayAs: d)
            }
            let best = dayFasts.map { $0.elapsedSeconds / 3600 }.max() ?? 0
            let hit = dayFasts.contains { $0.didReachGoal }
            bars.append(DayBar(date: d, hours: best, hitGoal: hit))
        }

        return FastStats(total: fasts.count,
                         completed: finished.count,
                         goalsHit: goalsHit,
                         averageHours: avg,
                         longestHours: longest,
                         totalHours: totalH,
                         currentStreakDays: streak,
                         last7: bars)
    }
}
