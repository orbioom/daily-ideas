import Foundation
import SwiftData

/// A façade over the SwiftData store for reads/writes that don't belong in a
/// View. Owns no state of its own; it borrows a `ModelContext`. All array access
/// is guarded and there are no force-unwraps.
@MainActor
struct ProgressStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Fetch helpers

    func allProgress() -> [CountryProgress] {
        let descriptor = FetchDescriptor<CountryProgress>()
        return (try? context.fetch(descriptor)) ?? []
    }

    func progress(for iso2: String) -> CountryProgress? {
        let descriptor = FetchDescriptor<CountryProgress>(
            predicate: #Predicate { $0.iso2 == iso2 }
        )
        return (try? context.fetch(descriptor))?.first
    }

    /// Fetch or create the record for a country, inserting if needed.
    @discardableResult
    func ensure(_ iso2: String) -> CountryProgress {
        if let existing = progress(for: iso2) { return existing }
        let created = CountryProgress(iso2: iso2)
        context.insert(created)
        return created
    }

    // MARK: Mutations

    /// Record one graded answer and persist.
    func recordAnswer(iso2: String, correct: Bool) {
        let record = ensure(iso2)
        record.seen += 1
        if correct { record.correct += 1 }
        record.lastSeen = Date()
        save()
    }

    func toggleStar(_ iso2: String) {
        let record = ensure(iso2)
        record.starred.toggle()
        save()
    }

    func isStarred(_ iso2: String) -> Bool {
        progress(for: iso2)?.starred ?? false
    }

    func saveSession(_ session: QuizSession) {
        context.insert(session)
        save()
    }

    /// Delete all progress and sessions (Settings → Reset).
    func resetAll() {
        for p in allProgress() { context.delete(p) }
        let sessions = (try? context.fetch(FetchDescriptor<QuizSession>())) ?? []
        for s in sessions { context.delete(s) }
        save()
    }

    func save() {
        do { try context.save() }
        catch { /* Non-fatal: SwiftData autosave will retry; never crash a user path. */ }
    }

    // MARK: Snapshot for the engine

    func masterySnapshot() -> QuizEngine.MasterySnapshot {
        var mastery: [String: Double] = [:]
        var seen: [String: Int] = [:]
        for p in allProgress() {
            mastery[p.iso2] = p.mastery
            seen[p.iso2] = p.seen
        }
        return QuizEngine.MasterySnapshot(mastery: mastery, seen: seen)
    }
}
