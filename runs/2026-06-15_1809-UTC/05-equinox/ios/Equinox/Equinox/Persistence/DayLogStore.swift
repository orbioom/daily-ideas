import Foundation
import SwiftData

/// Pure helpers for the one-log-per-day invariant. Kept free of UI so it can be reused
/// from any view's `modelContext`. All fetches are guarded; failures degrade to empty.
enum DayLogStore {

    /// Returns the existing log for the given day, or nil. Normalizes to start-of-day.
    static func log(on date: Date, context: ModelContext) -> DayLog? {
        let day = Calendar.current.startOfDay(for: date)
        guard let next = Calendar.current.date(byAdding: .day, value: 1, to: day) else { return nil }
        let predicate = #Predicate<DayLog> { $0.date >= day && $0.date < next }
        var descriptor = FetchDescriptor<DayLog>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Returns the existing log for the day, or creates and inserts a fresh one.
    @discardableResult
    static func logOrCreate(on date: Date, context: ModelContext) -> DayLog {
        if let existing = log(on: date, context: context) { return existing }
        let fresh = DayLog(date: date)
        context.insert(fresh)
        return fresh
    }

    /// All logs, newest first.
    static func allLogs(context: ModelContext) -> [DayLog] {
        let descriptor = FetchDescriptor<DayLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            // Non-fatal: SwiftData autosaves on the next runloop; surface nothing destructive.
            // Views that need to confirm success do so via their own state, not a crash.
        }
    }
}
