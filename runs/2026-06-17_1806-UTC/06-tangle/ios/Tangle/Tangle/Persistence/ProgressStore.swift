import Foundation
import SwiftData

/// Thin helper around the ModelContext for the small set of writes Tangle needs.
/// All fetches are guarded; failures degrade gracefully (return defaults / no-op).
@MainActor
struct ProgressStore {
    let context: ModelContext

    // MARK: - Level progress

    func progress(for levelID: String) -> LevelProgress? {
        let predicate = #Predicate<LevelProgress> { $0.levelID == levelID }
        var descriptor = FetchDescriptor<LevelProgress>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Record (or upgrade) a level completion. Keeps the best stars/bonus seen.
    func recordCompletion(levelID: String, stars: Int, bonusFound: Int) {
        if let existing = progress(for: levelID) {
            existing.completed = true
            existing.starsEarned = max(existing.starsEarned, stars)
            existing.bonusFoundCount = max(existing.bonusFoundCount, bonusFound)
            existing.completedAt = .now
        } else {
            context.insert(LevelProgress(
                levelID: levelID, completed: true,
                starsEarned: stars, bonusFoundCount: bonusFound, completedAt: .now
            ))
        }
        try? context.save()
    }

    // MARK: - Bonus words

    func bonusWord(_ word: String) -> FoundBonusWord? {
        let upper = word.uppercased()
        let predicate = #Predicate<FoundBonusWord> { $0.word == upper }
        var descriptor = FetchDescriptor<FoundBonusWord>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Insert or bump a discovered bonus word (de-duplicated by spelling).
    func recordBonus(word: String, levelID: String) {
        if let existing = bonusWord(word) {
            existing.timesFound += 1
        } else {
            context.insert(FoundBonusWord(word: word, firstFoundLevel: levelID))
        }
        try? context.save()
    }

    // MARK: - Daily

    func dailyResult(for dateKey: String) -> DailyResult? {
        let predicate = #Predicate<DailyResult> { $0.dateKey == dateKey }
        var descriptor = FetchDescriptor<DailyResult>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    func recordDaily(dateKey: String, stars: Int) {
        if let existing = dailyResult(for: dateKey) {
            existing.completed = true
            existing.stars = max(existing.stars, stars)
            existing.completedAt = .now
        } else {
            context.insert(DailyResult(dateKey: dateKey, completed: true, stars: stars, completedAt: .now))
        }
        try? context.save()
    }

    /// Current consecutive-day streak ending today (if today is done) or yesterday.
    func dailyStreak() -> Int {
        let descriptor = FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.completed == true },
            sortBy: [SortDescriptor(\.dateKey, order: .reverse)]
        )
        guard let results = try? context.fetch(descriptor), !results.isEmpty else { return 0 }
        let keys = results.map { $0.dateKey }
        let keySet = Set(keys)
        let cal = Calendar(identifier: .gregorian)

        // Anchor: today if completed, else yesterday if completed, else 0.
        let todayKey = DateKey.key()
        var anchor: Date
        if keySet.contains(todayKey) {
            anchor = Date()
        } else if let yesterday = cal.date(byAdding: .day, value: -1, to: Date()),
                  keySet.contains(DateKey.key(for: yesterday)) {
            anchor = yesterday
        } else {
            return 0
        }

        var streak = 0
        var cursor = anchor
        while keySet.contains(DateKey.key(for: cursor)) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
