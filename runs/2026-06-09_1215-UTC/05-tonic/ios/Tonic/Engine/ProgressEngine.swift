import Foundation

/// Derives the summary numbers, streak, and chart series the Progress screen shows
/// from logged sessions and per-item stats. Pure functions; no I/O.
enum ProgressEngine {

    struct Summary {
        var totalSessions: Int
        var totalQuestions: Int
        var totalCorrect: Int
        var overallAccuracy: Double
        var currentStreak: Int
    }

    struct DailyPoint: Identifiable {
        let id = UUID()
        let date: Date
        let accuracy: Double      // 0…1, averaged over that day's sessions
        let questions: Int
    }

    struct WeeklyPoint: Identifiable {
        let id = UUID()
        let weekStart: Date
        let sessions: Int
    }

    static func summary(_ sessions: [DrillSession]) -> Summary {
        let totalQ = sessions.reduce(0) { $0 + $1.total }
        let totalC = sessions.reduce(0) { $0 + $1.correct }
        let acc = totalQ > 0 ? Double(totalC) / Double(totalQ) : 0
        return Summary(totalSessions: sessions.count,
                       totalQuestions: totalQ,
                       totalCorrect: totalC,
                       overallAccuracy: acc,
                       currentStreak: currentStreak(sessions))
    }

    /// Consecutive days (ending today or yesterday) with at least one session.
    static func currentStreak(_ sessions: [DrillSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) })
        var streak = 0
        var day = cal.startOfDay(for: .now)
        // Allow the streak to count from today or yesterday.
        if !days.contains(day) {
            guard let y = cal.date(byAdding: .day, value: -1, to: day), days.contains(y) else {
                return 0
            }
            day = y
        }
        while days.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    /// Accuracy per day over the last `days` days (oldest → newest).
    static func dailyAccuracy(_ sessions: [DrillSession], days: Int) -> [DailyPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var points: [DailyPoint] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let inDay = sessions.filter { cal.isDate($0.date, inSameDayAs: day) }
            let q = inDay.reduce(0) { $0 + $1.total }
            let c = inDay.reduce(0) { $0 + $1.correct }
            let acc = q > 0 ? Double(c) / Double(q) : 0
            points.append(DailyPoint(date: day, accuracy: acc, questions: q))
        }
        return points
    }

    /// Session counts per ISO week over the last `weeks` weeks (oldest → newest).
    static func weeklySessions(_ sessions: [DrillSession], weeks: Int) -> [WeeklyPoint] {
        let cal = Calendar.current
        let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: .now)?.start
            ?? cal.startOfDay(for: .now)
        var points: [WeeklyPoint] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart)
            else { continue }
            let count = sessions.filter {
                guard let s = cal.dateInterval(of: .weekOfYear, for: $0.date)?.start else { return false }
                return cal.isDate(s, inSameDayAs: weekStart)
            }.count
            points.append(WeeklyPoint(weekStart: weekStart, sessions: count))
        }
        return points
    }

    /// Mastery rows (one per practiced item) sorted weakest-first, grouped-ready.
    static func mastery(_ stats: [ItemStat], type: DrillType) -> [ItemStat] {
        stats
            .filter { $0.drillType == type && $0.attempts > 0 }
            .sorted { $0.accuracy < $1.accuracy }
    }
}
