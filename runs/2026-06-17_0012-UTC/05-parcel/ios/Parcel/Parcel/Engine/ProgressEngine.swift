import Foundation

/// Pure, stateless computations over the user's study statistics and exam history.
/// Everything here guards against division by zero and empty collections.
enum ProgressEngine {

    /// Overall exam readiness, 0...1. Blends average mastery of seen questions with
    /// how much of the bank has been covered, so a high score on a few questions does
    /// not falsely read as "ready".
    static func readiness(stats: [QuestionStat], totalQuestions: Int) -> Double {
        guard totalQuestions > 0 else { return 0 }
        let seen = stats.filter { $0.seen > 0 }
        guard !seen.isEmpty else { return 0 }
        let avgMastery = seen.reduce(0.0) { $0 + $1.mastery } / Double(seen.count)
        let coverage = min(1.0, Double(seen.count) / Double(totalQuestions))
        // Coverage gates readiness: full credit only with broad coverage.
        let value = avgMastery * (0.45 + 0.55 * coverage)
        return min(1.0, max(0.0, value))
    }

    /// Fraction of the bank the user has attempted at least once, 0...1.
    static func coverage(stats: [QuestionStat], totalQuestions: Int) -> Double {
        guard totalQuestions > 0 else { return 0 }
        let seen = stats.filter { $0.seen > 0 }.count
        return min(1.0, Double(seen) / Double(totalQuestions))
    }

    /// Mastery for a single topic, 0...1, coverage-weighted within the topic.
    static func topicMastery(_ topic: Topic, stats: [QuestionStat]) -> Double {
        let ids = Set(QuestionBank.forTopic(topic).map { $0.id })
        guard !ids.isEmpty else { return 0 }
        let topicStats = stats.filter { ids.contains($0.questionId) && $0.seen > 0 }
        guard !topicStats.isEmpty else { return 0 }
        let avg = topicStats.reduce(0.0) { $0 + $1.mastery } / Double(topicStats.count)
        let cov = Double(topicStats.count) / Double(ids.count)
        return min(1.0, avg * (0.4 + 0.6 * cov))
    }

    /// Topics sorted weakest-first, restricted to those with room to improve.
    static func weakestTopics(stats: [QuestionStat], limit: Int = 3) -> [Topic] {
        Topic.allCases
            .map { ($0, topicMastery($0, stats: stats)) }
            .sorted { $0.1 < $1.1 }
            .prefix(max(0, limit))
            .map { $0.0 }
    }

    /// Fraction of mock exams that passed, 0...1.
    static func passRate(results: [ExamResult]) -> Double {
        let mocks = results.filter { $0.modeRaw == ExamMode.mock.rawValue }
        guard !mocks.isEmpty else { return 0 }
        let passed = mocks.filter { $0.passed }.count
        return Double(passed) / Double(mocks.count)
    }

    /// Consecutive-day study streak ending today (or yesterday) given result dates.
    static func studyStreak(results: [ExamResult], now: Date = Date(),
                            calendar: Calendar = .current) -> Int {
        guard !results.isEmpty else { return 0 }
        let days = Set(results.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        // Allow the streak to count if the most recent activity was today or yesterday.
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

    /// Total number of questions answered across all sessions (seen counts).
    static func totalAnswered(stats: [QuestionStat]) -> Int {
        stats.reduce(0) { $0 + $1.seen }
    }
}
