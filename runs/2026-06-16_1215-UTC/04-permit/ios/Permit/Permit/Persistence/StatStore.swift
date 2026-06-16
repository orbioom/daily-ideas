import Foundation
import SwiftData

/// Helper that records answers and flags into SwiftData, fetching-or-creating stats safely.
@MainActor
enum StatStore {

    static func stat(for questionID: Int, in context: ModelContext) -> QuestionStat {
        let descriptor = FetchDescriptor<QuestionStat>(
            predicate: #Predicate { $0.questionID == questionID }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let created = QuestionStat(questionID: questionID)
        context.insert(created)
        return created
    }

    /// Record the outcome of answering a question.
    static func record(questionID: Int, correct: Bool, in context: ModelContext, date: Date = .now) {
        let s = stat(for: questionID, in: context)
        s.record(correct: correct, date: date)
        try? context.save()
    }

    /// Toggle the flagged state of a question and return the new value.
    @discardableResult
    static func toggleFlag(questionID: Int, in context: ModelContext) -> Bool {
        let s = stat(for: questionID, in: context)
        s.isFlagged.toggle()
        try? context.save()
        return s.isFlagged
    }

    static func isFlagged(questionID: Int, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<QuestionStat>(
            predicate: #Predicate { $0.questionID == questionID }
        )
        return (try? context.fetch(descriptor))?.first?.isFlagged ?? false
    }

    /// Save a finished exam result.
    static func saveResult(_ result: ExamResult, in context: ModelContext) {
        context.insert(result)
        try? context.save()
    }

    /// Delete all user progress (stats + results). Used by Settings → Reset.
    static func resetAll(in context: ModelContext) {
        if let stats = try? context.fetch(FetchDescriptor<QuestionStat>()) {
            for s in stats { context.delete(s) }
        }
        if let results = try? context.fetch(FetchDescriptor<ExamResult>()) {
            for r in results { context.delete(r) }
        }
        try? context.save()
        // Keep the seed flag set so a reset stays empty and sample data is NOT regenerated on relaunch.
        UserDefaults.standard.set(true, forKey: SeedData.seedFlagKey)
    }
}
