import Foundation
import SwiftData

/// Helper for reading/mutating QuestionStat rows. Keeps SwiftData fetch logic
/// out of the views. All methods are best-effort and never throw on user paths.
@MainActor
struct StatStore {
    let context: ModelContext

    /// Fetch (or lazily create) the stat row for a question number.
    func stat(for number: Int) -> QuestionStat {
        let descriptor = FetchDescriptor<QuestionStat>(
            predicate: #Predicate { $0.questionNumber == number }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let created = QuestionStat(questionNumber: number)
        context.insert(created)
        return created
    }

    /// All stats keyed by question number (missing numbers simply absent).
    func allStatsByNumber() -> [Int: QuestionStat] {
        let all = (try? context.fetch(FetchDescriptor<QuestionStat>())) ?? []
        return Dictionary(all.map { ($0.questionNumber, $0) }, uniquingKeysWith: { a, _ in a })
    }

    func recordSeen(_ number: Int, correct: Bool?) {
        let s = stat(for: number)
        s.timesSeen += 1
        if correct == true { s.timesCorrect += 1 }
        s.lastSeen = Date()
        save()
    }

    func setFlag(_ number: Int, flagged: Bool) {
        let s = stat(for: number)
        s.isFlagged = flagged
        save()
    }

    func toggleFlag(_ number: Int) -> Bool {
        let s = stat(for: number)
        s.isFlagged.toggle()
        save()
        return s.isFlagged
    }

    func markKnown(_ number: Int) {
        let s = stat(for: number)
        s.timesSeen += 1
        s.timesCorrect += 1
        s.lastSeen = Date()
        save()
    }

    func markNeedsReview(_ number: Int) {
        let s = stat(for: number)
        s.timesSeen += 1
        s.lastSeen = Date()
        save()
    }

    /// Delete all stats and exam results (used by "Reset progress").
    func resetAll() {
        let stats = (try? context.fetch(FetchDescriptor<QuestionStat>())) ?? []
        for s in stats { context.delete(s) }
        let results = (try? context.fetch(FetchDescriptor<ExamResult>())) ?? []
        for r in results { context.delete(r) }
        save()
    }

    func save() {
        do {
            try context.save()
        } catch {
            // Persistence save failure is non-fatal; the in-memory model is still
            // valid and will retry on the next mutation. Surface nothing to the user.
        }
    }
}
