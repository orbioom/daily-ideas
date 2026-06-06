import Foundation

/// Pure aggregation over logged sessions for the History screen. No SwiftData queries
/// here — it takes a snapshot array so it is trivially testable and preview-safe.
struct Insights {
    let sessions: [Session]

    var totalRuns: Int { sessions.count }

    var totalActiveSeconds: Int { sessions.reduce(0) { $0 + $1.activeSeconds } }

    var totalWorkSeconds: Int { sessions.reduce(0) { $0 + $1.workSeconds } }

    var fullyCompletedRuns: Int { sessions.filter { $0.finishedFully }.count }

    var completionRateText: String {
        guard totalRuns > 0 else { return "—" }
        let pct = Int((Double(fullyCompletedRuns) / Double(totalRuns) * 100).rounded())
        return "\(pct)%"
    }

    var runsThisWeek: Int {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) else {
            return 0
        }
        return sessions.filter { $0.startedAt >= weekAgo }.count
    }

    /// Consecutive days (counting back from today) that contain at least one run.
    var currentStreak: Int {
        guard !sessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        let runDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        guard !runDays.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: .now)
        // Allow the streak to begin today or yesterday (so a missed "today so far"
        // doesn't immediately zero a streak earned yesterday).
        if !runDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  runDays.contains(yesterday) else {
                return 0
            }
            day = yesterday
        }
        while runDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    var streakSubtitle: String {
        if currentStreak == 0 { return "Run today to start a streak." }
        return "Keep it going — run again today."
    }
}
