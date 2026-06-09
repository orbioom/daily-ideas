import Foundation
import SwiftData

/// Shared mutation helpers for completing tasks. Keeps the "mark done" flow —
/// update `lastDone`, write an independent `CompletionLog`, persist — in one
/// place so Today and Room Detail behave identically.
enum TaskActions {

    /// Mark a task done now: stamp `lastDone`, append a history log, and save.
    /// Returns silently on save failure (history simply isn't recorded) rather
    /// than crashing on a user path.
    static func markDone(_ task: CleaningTask, context: ModelContext, now: Date = .now) {
        task.lastDone = now
        let roomName = task.room?.name ?? task.roomName
        let log = CompletionLog(date: now,
                                taskName: task.name,
                                roomName: roomName.isEmpty ? "Home" : roomName,
                                minutes: task.estMinutes)
        context.insert(log)
        try? context.save()
        Haptics.success()
    }

    /// Snooze isn't supported, but undoing the most recent completion is useful.
    /// Clears `lastDone` back to nil. (History logs are kept on purpose.)
    static func clearLastDone(_ task: CleaningTask, context: ModelContext) {
        task.lastDone = nil
        try? context.save()
    }
}
