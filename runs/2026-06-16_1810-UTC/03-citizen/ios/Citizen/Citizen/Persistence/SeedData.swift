import Foundation
import SwiftData

/// One-time seeding so Progress charts and history aren't empty on first open.
/// Idempotent: guarded by an @AppStorage flag set by the app on launch.
@MainActor
enum SeedData {

    /// Insert a small fixed seed of prior exam results spread over recent days,
    /// plus light stats so readiness/coverage are non-zero. Safe to skip if data exists.
    static func seedIfNeeded(context: ModelContext) {
        // Only seed when there are no exam results yet.
        let existing = (try? context.fetch(FetchDescriptor<ExamResult>())) ?? []
        guard existing.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()

        // A handful of prior mock results showing an improving trend.
        let seeds: [(daysAgo: Int, score: Int, total: Int, duration: Int)] = [
            (18, 4, 10, 540),
            (12, 5, 10, 500),
            (7, 6, 10, 470),
            (3, 7, 10, 430),
            (1, 8, 10, 410),
        ]

        for seed in seeds {
            let date = calendar.date(byAdding: .day, value: -seed.daysAgo, to: now) ?? now
            let passed = seed.score >= ExamMode.mock.passThreshold(total: seed.total)
            let result = ExamResult(date: date,
                                    mode: ExamMode.mock.rawValue,
                                    score: seed.score,
                                    total: seed.total,
                                    passed: passed,
                                    durationSeconds: seed.duration)
            context.insert(result)
        }

        // Seed light stats for the first ~30 questions so coverage/mastery are visible.
        for q in CivicsContent.questions.prefix(30) {
            let seen = 2 + (q.number % 3)
            let correct = max(1, seen - (q.number % 2))
            let daysAgo = (q.number % 6) + 1
            let lastSeen = calendar.date(byAdding: .day, value: -daysAgo, to: now)
            let stat = QuestionStat(questionNumber: q.number,
                                    timesSeen: seen,
                                    timesCorrect: min(correct, seen),
                                    lastSeen: lastSeen,
                                    isFlagged: q.number % 11 == 0)
            context.insert(stat)
        }

        do {
            try context.save()
        } catch {
            // Seeding is best-effort; an empty store simply shows empty states.
        }
    }
}
