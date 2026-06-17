import Foundation
import SwiftData

/// Thin helpers for reading/updating per-question stats in the SwiftData store.
/// Kept free of view state so any screen or the session can record results safely.
enum StatStore {

    /// Fetch the stat row for a question, creating and inserting one if absent.
    @MainActor
    static func stat(for questionId: Int, in context: ModelContext) -> QuestionStat {
        let descriptor = FetchDescriptor<QuestionStat>(
            predicate: #Predicate { $0.questionId == questionId }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let created = QuestionStat(questionId: questionId)
        context.insert(created)
        return created
    }

    /// Record the outcome of answering a question.
    @MainActor
    static func record(questionId: Int, correct: Bool, in context: ModelContext) {
        let s = stat(for: questionId, in: context)
        s.seen += 1
        if correct { s.correct += 1 } else { s.wrong += 1 }
        s.lastSeen = Date()
    }

    /// Toggle the flagged state for a question and return the new value.
    @MainActor
    @discardableResult
    static func toggleFlag(questionId: Int, in context: ModelContext) -> Bool {
        let s = stat(for: questionId, in: context)
        s.flagged.toggle()
        if s.lastSeen == nil { s.lastSeen = Date() }
        return s.flagged
    }

    /// All stat rows currently stored.
    @MainActor
    static func all(in context: ModelContext) -> [QuestionStat] {
        (try? context.fetch(FetchDescriptor<QuestionStat>())) ?? []
    }

    /// Ids of questions the user has missed at least once or flagged — the Review pool.
    @MainActor
    static func reviewPoolIds(in context: ModelContext) -> [Int] {
        all(in: context)
            .filter { $0.wrong > 0 || $0.flagged }
            .map { $0.questionId }
    }
}
