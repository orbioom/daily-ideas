import Foundation

struct RunStatsResult {
    let totalRuns: Int
    let totalDistanceKm: Double
    let totalDurationSeconds: Double
    let averagePaceSecondsPerKm: Double
    let bestPaceSecondsPerKm: Double
    let longestRunKm: Double
    let currentStreak: Int
    let weeklyDistanceKm: Double

    static let empty = RunStatsResult(
        totalRuns: 0,
        totalDistanceKm: 0,
        totalDurationSeconds: 0,
        averagePaceSecondsPerKm: 0,
        bestPaceSecondsPerKm: 0,
        longestRunKm: 0,
        currentStreak: 0,
        weeklyDistanceKm: 0
    )
}

struct PaceStats {
    static func compute(from sessions: [RunSession]) -> RunStatsResult {
        guard !sessions.isEmpty else { return .empty }

        let total = sessions.count
        let totalDist = sessions.reduce(0.0) { $0 + $1.distanceKm }
        let totalDur = sessions.reduce(0.0) { $0 + $1.duration }

        let validPaces = sessions.filter { $0.paceSecondsPerKm > 0 && $0.paceSecondsPerKm < 3600 }
        let avgPace = validPaces.isEmpty
            ? 0
            : validPaces.reduce(0.0) { $0 + $1.paceSecondsPerKm } / Double(validPaces.count)
        let bestPace = validPaces.min { $0.paceSecondsPerKm < $1.paceSecondsPerKm }?.paceSecondsPerKm ?? 0
        let longestRun = sessions.max { $0.distanceKm < $1.distanceKm }?.distanceKm ?? 0

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        let sessionDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        while sessionDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) ?? today
        let weeklyDist = sessions.filter { $0.date >= startOfWeek }.reduce(0.0) { $0 + $1.distanceKm }

        return RunStatsResult(
            totalRuns: total,
            totalDistanceKm: totalDist,
            totalDurationSeconds: totalDur,
            averagePaceSecondsPerKm: avgPace,
            bestPaceSecondsPerKm: bestPace,
            longestRunKm: longestRun,
            currentStreak: streak,
            weeklyDistanceKm: weeklyDist
        )
    }

    static func weeklyDistances(from sessions: [RunSession], weeks: Int = 8) -> [(Date, Double)] {
        let calendar = Calendar.current
        let today = Date()
        var result: [(Date, Double)] = []

        for i in 0..<weeks {
            let baseWeekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            ) ?? today
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: baseWeekStart),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)
            else { continue }

            let dist = sessions
                .filter { $0.date >= weekStart && $0.date < weekEnd }
                .reduce(0.0) { $0 + $1.distanceKm }
            result.insert((weekStart, dist), at: 0)
        }
        return result
    }

    static func formatPace(_ secondsPerKm: Double) -> String {
        guard secondsPerKm > 0 && secondsPerKm < 3600 else { return "--:--" }
        let m = Int(secondsPerKm) / 60
        let s = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", m, s)
    }

    static func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, s)
    }
}
