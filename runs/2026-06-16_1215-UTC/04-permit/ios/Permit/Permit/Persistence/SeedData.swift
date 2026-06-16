import Foundation
import SwiftData

/// Seeds plausible sample progress on first run so the Progress screen isn't empty.
@MainActor
enum SeedData {
    static let seedFlagKey = "didSeedSampleData"

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: seedFlagKey) == false else { return }

        // Guard against double-seeding if any stats already exist.
        let existing = (try? context.fetch(FetchDescriptor<QuestionStat>()))?.isEmpty ?? true
        guard existing else {
            defaults.set(true, forKey: seedFlagKey)
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // 1) Seed a handful of QuestionStats with varied accuracy and a few mastered/flagged.
        let bank = QuestionBank.all
        let seedCount = min(34, bank.count)
        for i in 0..<seedCount {
            let q = bank[i]
            let stat = QuestionStat(questionID: q.id)
            // Vary the record so categories show different mastery.
            switch i % 5 {
            case 0: // mastered
                stat.timesSeen = 4; stat.timesCorrect = 4; stat.correctStreak = 4
            case 1: // strong
                stat.timesSeen = 3; stat.timesCorrect = 3; stat.correctStreak = 3
            case 2: // mixed
                stat.timesSeen = 3; stat.timesCorrect = 2; stat.correctStreak = 1
            case 3: // weak
                stat.timesSeen = 2; stat.timesCorrect = 0; stat.correctStreak = 0
            default: // seen once, correct
                stat.timesSeen = 1; stat.timesCorrect = 1; stat.correctStreak = 1
            }
            // Flag a few for the review list.
            stat.isFlagged = (i % 9 == 0)
            // Spread lastSeen across the past several days to build a streak/history.
            let daysAgo = i % 6
            stat.lastSeen = calendar.date(byAdding: .day, value: -daysAgo, to: now)
            context.insert(stat)
        }

        // 2) Seed 4 sample ExamResults across recent days showing improvement.
        let samples: [(daysAgo: Int, mode: ExamMode, total: Int, correct: Int)] = [
            (8, .fullMock, 40, 26),
            (5, .quickMock, 20, 15),
            (3, .fullMock, 40, 31),
            (1, .fullMock, 40, 34)
        ]
        for s in samples {
            let date = calendar.date(byAdding: .day, value: -s.daysAgo, to: now) ?? now
            let passThreshold = (s.mode == .fullMock || s.mode == .quickMock) ? 0.8 : 0.8
            let required = Int((Double(s.total) * passThreshold).rounded(.up))
            let passed = s.correct >= required
            // Plausible missed IDs sampled from the bank.
            let missed = Array(bank.suffix(max(0, s.total - s.correct)).prefix(max(0, s.total - s.correct)).map { $0.id })
            let result = ExamResult(
                date: date,
                modeRaw: s.mode.rawValue,
                categoryRaw: nil,
                total: s.total,
                correct: s.correct,
                passed: passed,
                durationSec: 60 * 12 + s.daysAgo * 7,
                missedIDs: missed
            )
            context.insert(result)
        }

        try? context.save()
        defaults.set(true, forKey: seedFlagKey)
    }
}
