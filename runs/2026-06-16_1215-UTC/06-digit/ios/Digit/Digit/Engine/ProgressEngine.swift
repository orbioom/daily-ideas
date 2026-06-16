import Foundation

/// Aggregated, parent-facing progress metrics. Pure functions, all guarded.
enum ProgressEngine {

    struct OpSummary: Identifiable {
        let op: MathOp
        var id: String { op.rawValue }
        let totalFacts: Int
        let masteredFacts: Int
        /// Average mastery fraction across known facts (0...1).
        let masteryFraction: Double
        let accuracy: Double
        let avgSpeedMs: Int?
    }

    /// Per-op mastery summary for a profile's facts, limited to its enabled ops.
    static func opSummaries(facts: [FactStat], ops: [MathOp]) -> [OpSummary] {
        ops.map { op in
            let group = facts.filter { $0.op == op }
            let total = group.count
            let mastered = group.filter { $0.masteryLevel >= 3 }.count
            let masterySum = group.reduce(0) { $0 + max(0, min(3, $1.masteryLevel)) }
            let masteryFraction = total > 0 ? Double(masterySum) / Double(total * 3) : 0
            let seen = group.filter { $0.timesSeen > 0 }
            let seenCount = seen.reduce(0) { $0 + $1.timesSeen }
            let correctCount = seen.reduce(0) { $0 + $1.timesCorrect }
            let accuracy = seenCount > 0 ? Double(correctCount) / Double(seenCount) : 0
            let speeds = group.compactMap { $0.fastestMs }
            let avgSpeed = speeds.isEmpty ? nil : speeds.reduce(0, +) / speeds.count
            return OpSummary(op: op,
                             totalFacts: total,
                             masteredFacts: mastered,
                             masteryFraction: masteryFraction,
                             accuracy: accuracy,
                             avgSpeedMs: avgSpeed)
        }
    }

    /// Total facts the child has mastered (level 3) across all ops.
    static func totalMastered(facts: [FactStat]) -> Int {
        facts.filter { $0.masteryLevel >= 3 }.count
    }

    /// Overall accuracy across every answered question.
    static func overallAccuracy(facts: [FactStat]) -> Double {
        let seen = facts.reduce(0) { $0 + $1.timesSeen }
        let correct = facts.reduce(0) { $0 + $1.timesCorrect }
        return seen > 0 ? Double(correct) / Double(seen) : 0
    }

    /// Average best answer speed in seconds, or nil if no timed facts.
    static func avgSpeedSeconds(facts: [FactStat]) -> Double? {
        let speeds = facts.compactMap { $0.fastestMs }
        guard !speeds.isEmpty else { return nil }
        return Double(speeds.reduce(0, +)) / Double(speeds.count) / 1000.0
    }

    static func totalStars(sessions: [Session]) -> Int {
        sessions.reduce(0) { $0 + $1.starsEarned }
    }

    /// Day streak: consecutive calendar days (ending today or yesterday) with ≥1 session.
    static func dayStreak(sessions: [Session], now: Date = .now,
                          calendar: Calendar = .current) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let days = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: now)

        // Streak must include today or yesterday to be "current".
        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Whether a level is "passed" — mastery fraction across its facts ≥ threshold.
    static func isLevelPassed(_ level: Level, facts: [FactStat]) -> Bool {
        let progress = levelProgress(level, facts: facts)
        return progress >= Curriculum.passThreshold
    }

    /// Mastery progress (0...1) for one level across the facts in its ops.
    static func levelProgress(_ level: Level, facts: [FactStat]) -> Double {
        let relevant = facts.filter { level.ops.contains($0.op) && $0.a <= level.maxNumber && $0.b <= level.maxNumber }
        guard !relevant.isEmpty else { return 0 }
        let sum = relevant.reduce(0) { $0 + max(0, min(3, $1.masteryLevel)) }
        return Double(sum) / Double(relevant.count * 3)
    }

    /// A line-chart point for sessions over time.
    struct SessionPoint: Identifiable {
        let id: UUID
        let date: Date
        let accuracy: Double
        let avgSecPerQuestion: Double
        let starsEarned: Int
    }

    static func sessionPoints(sessions: [Session], limit: Int = 12) -> [SessionPoint] {
        let sorted = sessions.sorted { $0.date < $1.date }
        let trimmed = sorted.suffix(max(1, limit))
        return trimmed.map {
            SessionPoint(id: $0.id, date: $0.date,
                         accuracy: $0.accuracy,
                         avgSecPerQuestion: $0.avgSecPerQuestion,
                         starsEarned: $0.starsEarned)
        }
    }

    /// Facts-mastered-over-time, derived from cumulative session activity (approx via dates).
    struct MasteredPoint: Identifiable {
        let id: UUID
        let date: Date
        let cumulativeStars: Int
    }

    static func masteredOverTime(sessions: [Session]) -> [MasteredPoint] {
        let sorted = sessions.sorted { $0.date < $1.date }
        var running = 0
        return sorted.map {
            running += $0.starsEarned
            return MasteredPoint(id: $0.id, date: $0.date, cumulativeStars: running)
        }
    }

    /// Distinct practice days in the last `span` days (for the streak calendar).
    static func practiceDays(sessions: [Session], span: Int = 35,
                             now: Date = .now, calendar: Calendar = .current) -> Set<Date> {
        let cutoff = calendar.date(byAdding: .day, value: -span, to: calendar.startOfDay(for: now))
            ?? calendar.startOfDay(for: now)
        return Set(sessions
            .map { calendar.startOfDay(for: $0.date) }
            .filter { $0 >= cutoff })
    }
}
