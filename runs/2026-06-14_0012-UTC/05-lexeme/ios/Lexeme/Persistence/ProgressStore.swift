import Foundation
import SwiftData

/// Thin helper around `ModelContext` for the WordProgress / StudySession mutations
/// Lexeme needs. Centralizes fetch-or-create and grading so views stay declarative.
@MainActor
struct ProgressStore {
    let context: ModelContext

    // MARK: - Fetch

    func allProgress() -> [WordProgress] {
        (try? context.fetch(FetchDescriptor<WordProgress>())) ?? []
    }

    func allSessions() -> [StudySession] {
        let desc = FetchDescriptor<StudySession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? context.fetch(desc)) ?? []
    }

    /// Returns the existing row for a word, or creates and inserts a fresh one.
    @discardableResult
    func progress(for wordID: String) -> WordProgress {
        let target = wordID.lowercased()
        let desc = FetchDescriptor<WordProgress>(predicate: #Predicate { $0.wordID == target })
        if let existing = try? context.fetch(desc).first {
            return existing
        }
        let fresh = WordProgress(wordID: target, nextReview: Date())
        context.insert(fresh)
        return fresh
    }

    func existingProgress(for wordID: String) -> WordProgress? {
        let target = wordID.lowercased()
        let desc = FetchDescriptor<WordProgress>(predicate: #Predicate { $0.wordID == target })
        return try? context.fetch(desc).first
    }

    // MARK: - Mutations

    /// Grades an answer: updates level, schedule, counters; returns before/after levels.
    @discardableResult
    func grade(wordID: String, correct: Bool, now: Date = Date()) -> (previous: Int, new: Int) {
        let p = progress(for: wordID)
        let previous = p.level
        let newLevel = LexemeEngine.updatedLevel(current: previous, correct: correct)
        p.level = newLevel
        p.seen += 1
        if correct { p.correct += 1 }
        p.lastSeen = now
        p.nextReview = LexemeEngine.nextReviewDate(forLevel: newLevel, from: now)
        if LexemeEngine.isMastered(level: newLevel) { p.learned = true }
        save()
        return (previous, newLevel)
    }

    /// Marks a word as known ("I knew it") — jumps it up the schedule.
    func markKnown(wordID: String, now: Date = Date()) {
        let p = progress(for: wordID)
        p.learned = true
        p.level = max(p.level, LexemeEngine.maxLevel - 1)
        p.lastSeen = now
        p.nextReview = LexemeEngine.nextReviewDate(forLevel: p.level, from: now)
        save()
    }

    /// Marks a word as "learning" — adds it to the review schedule at a low level.
    func markLearning(wordID: String, now: Date = Date()) {
        let p = progress(for: wordID)
        p.learned = false
        if p.seen == 0 { p.level = 0 }
        p.lastSeen = now
        p.nextReview = LexemeEngine.nextReviewDate(forLevel: p.level, from: now)
        save()
    }

    func toggleFavorite(wordID: String) {
        let p = progress(for: wordID)
        p.favorite.toggle()
        save()
    }

    /// Schedules a word for review without changing learned state ("add to review").
    func addToReview(wordID: String, now: Date = Date()) {
        let p = progress(for: wordID)
        p.nextReview = now
        save()
    }

    func recordSession(mode: QuizMode?, total: Int, correct: Int, duration: Double, now: Date = Date()) {
        let session = StudySession(date: now,
                                   modeRaw: mode?.rawValue ?? "mixed",
                                   total: total, correct: correct, durationSec: duration)
        context.insert(session)
        save()
    }

    func resetAll() {
        for p in allProgress() { context.delete(p) }
        for s in allSessions() { context.delete(s) }
        save()
    }

    // MARK: - Save

    func save() {
        do { try context.save() }
        catch { context.rollback() }
    }
}
