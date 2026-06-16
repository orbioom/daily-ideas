import Foundation

/// Aggregate study analytics derived from stats + exam results. Pure functions.
enum ProgressEngine {

    /// Overall readiness 0...1: mean mastery across all 100 questions
    /// (unseen questions count as 0, so coverage matters).
    static func readiness(stats: [QuestionStat]) -> Double {
        let total = CivicsContent.questions.count
        guard total > 0 else { return 0 }
        let byNumber = Dictionary(stats.map { ($0.questionNumber, $0) }, uniquingKeysWith: { a, _ in a })
        let sum = CivicsContent.questions.reduce(0.0) { acc, q in
            acc + (byNumber[q.number]?.mastery ?? 0)
        }
        return sum / Double(total)
    }

    /// Number of distinct questions the user has seen at least once.
    static func coverage(stats: [QuestionStat]) -> Int {
        stats.filter { $0.timesSeen > 0 }.count
    }

    /// Per-category accuracy 0...1 (only over seen questions; 0 if none seen).
    static func categoryAccuracy(stats: [QuestionStat]) -> [CivicsCategory: Double] {
        let byNumber = Dictionary(stats.map { ($0.questionNumber, $0) }, uniquingKeysWith: { a, _ in a })
        var result: [CivicsCategory: Double] = [:]
        for category in CivicsCategory.allCases {
            let qs = CivicsContent.questions(in: category)
            let seen = qs.compactMap { byNumber[$0.number] }.filter { $0.timesSeen > 0 }
            guard !seen.isEmpty else { result[category] = 0; continue }
            let totalSeen = seen.reduce(0) { $0 + $1.timesSeen }
            let totalCorrect = seen.reduce(0) { $0 + $1.timesCorrect }
            result[category] = totalSeen > 0 ? Double(totalCorrect) / Double(totalSeen) : 0
        }
        return result
    }

    /// Per-category mastery 0...1 across all questions in the category (unseen = 0).
    static func categoryMastery(stats: [QuestionStat]) -> [CivicsCategory: Double] {
        let byNumber = Dictionary(stats.map { ($0.questionNumber, $0) }, uniquingKeysWith: { a, _ in a })
        var result: [CivicsCategory: Double] = [:]
        for category in CivicsCategory.allCases {
            let qs = CivicsContent.questions(in: category)
            guard !qs.isEmpty else { result[category] = 0; continue }
            let sum = qs.reduce(0.0) { $0 + (byNumber[$1.number]?.mastery ?? 0) }
            result[category] = sum / Double(qs.count)
        }
        return result
    }

    /// Overall pass rate across graded results (0...1). 0 when no results.
    static func passRate(results: [ExamResult]) -> Double {
        guard !results.isEmpty else { return 0 }
        let passes = results.filter { $0.passed }.count
        return Double(passes) / Double(results.count)
    }

    /// Study streak in days, counting back from today over days with activity.
    ///
    /// A day "counts" if any question was seen that day (per `lastSeen`) or any
    /// exam was taken that day.
    static func streak(stats: [QuestionStat], results: [ExamResult], now: Date = Date()) -> Int {
        let calendar = Calendar.current
        var activeDays = Set<Date>()
        for s in stats {
            if let last = s.lastSeen {
                activeDays.insert(calendar.startOfDay(for: last))
            }
        }
        for r in results {
            activeDays.insert(calendar.startOfDay(for: r.date))
        }
        guard !activeDays.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: now)

        // Allow the streak to "start" today or yesterday so a not-yet-studied
        // today doesn't immediately break a real streak.
        if !activeDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  activeDays.contains(yesterday) else {
                return 0
            }
            day = yesterday
        }

        while activeDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    /// Best (highest score fraction) result, if any.
    static func bestResult(results: [ExamResult]) -> ExamResult? {
        results.max { $0.fraction < $1.fraction }
    }
}
