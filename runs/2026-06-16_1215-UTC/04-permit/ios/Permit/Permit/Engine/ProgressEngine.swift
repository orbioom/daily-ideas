import Foundation

/// Per-category progress figures.
struct CategoryProgress: Identifiable {
    var id: String { category.rawValue }
    let category: QuestionCategory
    let totalQuestions: Int
    let seen: Int
    let mastered: Int
    let accuracy: Double   // 0–1 over answered attempts

    var masteryPercent: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(mastered) / Double(totalQuestions) * 100).rounded())
    }
    var accuracyPercent: Int { Int((accuracy * 100).rounded()) }
}

/// A single point on the mock-score trend line.
struct ScorePoint: Identifiable {
    let id = UUID()
    let date: Date
    let percent: Int
    let passed: Bool
}

/// Pure analytics over the user's QuestionStats and ExamResults. All math guarded.
enum ProgressEngine {

    /// Overall readiness: share of the whole bank that is mastered (streak >= 3),
    /// nudged by recent accuracy so an active learner sees movement.
    static func readiness(stats: [QuestionStat]) -> Int {
        let total = QuestionBank.count
        guard total > 0 else { return 0 }
        let mastered = stats.filter { $0.isMastered }.count
        let masteryShare = Double(mastered) / Double(total)
        return Int((masteryShare * 100).rounded())
    }

    static func masteredCount(stats: [QuestionStat]) -> Int {
        stats.filter { $0.isMastered }.count
    }

    static func categoryProgress(stats: [QuestionStat]) -> [CategoryProgress] {
        let statByID = Dictionary(stats.map { ($0.questionID, $0) }, uniquingKeysWith: { a, _ in a })
        return QuestionCategory.allCases.map { category in
            let questions = QuestionBank.questions(in: category)
            let total = questions.count
            var seen = 0
            var mastered = 0
            var attempts = 0
            var corrects = 0
            for q in questions {
                if let stat = statByID[q.id] {
                    if stat.timesSeen > 0 { seen += 1 }
                    if stat.isMastered { mastered += 1 }
                    attempts += stat.timesSeen
                    corrects += stat.timesCorrect
                }
            }
            let acc = attempts > 0 ? Double(corrects) / Double(attempts) : 0
            return CategoryProgress(category: category, totalQuestions: total, seen: seen, mastered: mastered, accuracy: acc)
        }
    }

    /// Mock-score trend (full + quick mocks), oldest first.
    static func mockTrend(results: [ExamResult]) -> [ScorePoint] {
        results
            .filter { $0.mode == .fullMock || $0.mode == .quickMock }
            .sorted { $0.date < $1.date }
            .map { ScorePoint(date: $0.date, percent: $0.scorePercent, passed: $0.passed) }
    }

    /// Pass rate over mock exams as a percentage (0 if none taken).
    static func passRate(results: [ExamResult]) -> Int {
        let mocks = results.filter { $0.mode == .fullMock || $0.mode == .quickMock }
        guard !mocks.isEmpty else { return 0 }
        let passed = mocks.filter { $0.passed }.count
        return Int((Double(passed) / Double(mocks.count) * 100).rounded())
    }

    static func mockCount(results: [ExamResult]) -> Int {
        results.filter { $0.mode == .fullMock || $0.mode == .quickMock }.count
    }

    /// Current study streak: consecutive days (ending today or yesterday) with any activity.
    static func studyStreak(stats: [QuestionStat], results: [ExamResult], calendar: Calendar = .current, now: Date = .now) -> Int {
        var activeDays = Set<Date>()
        for s in stats {
            if let d = s.lastSeen { activeDays.insert(calendar.startOfDay(for: d)) }
        }
        for r in results {
            activeDays.insert(calendar.startOfDay(for: r.date))
        }
        guard !activeDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: now)
        // Allow the streak to "count" if today or yesterday had activity.
        var cursor: Date
        if activeDays.contains(today) {
            cursor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), activeDays.contains(yesterday) {
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

    /// IDs of questions the learner has missed (last attempt wrong) or flagged, for review.
    static func reviewableIDs(stats: [QuestionStat]) -> (missed: [Int], flagged: [Int]) {
        var missed: [Int] = []
        var flagged: [Int] = []
        for s in stats {
            if s.isFlagged { flagged.append(s.questionID) }
            // "Missed" = has been seen and is not yet mastered with an imperfect record.
            if s.timesSeen > 0 && s.timesCorrect < s.timesSeen {
                missed.append(s.questionID)
            }
        }
        return (missed, flagged)
    }

    static func lastResult(results: [ExamResult]) -> ExamResult? {
        results.sorted { $0.date > $1.date }.first
    }
}
