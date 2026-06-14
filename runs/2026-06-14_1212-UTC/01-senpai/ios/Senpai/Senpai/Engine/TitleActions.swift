import Foundation
import SwiftData

/// Shared, guarded mutations on a `Title` — writing logs and keeping
/// status/dates consistent. Used by Up Next, Detail, and seeding.
enum TitleActions {

    /// Advance progress by `delta` units, writing a `WatchLog`. Auto-completes
    /// when reaching the known total. Returns true if the title just completed.
    @discardableResult
    static func advance(_ title: Title, by delta: Int, in context: ModelContext, note: String = "") -> Bool {
        guard delta != 0 else { return false }
        let from = max(0, title.progress)
        var to = from + delta

        // Clamp to total when known; never below zero.
        if let total = title.totalUnits, total > 0 {
            to = min(max(to, 0), total)
        } else {
            to = max(to, 0)
        }
        guard to != from else { return false }

        title.progress = to

        // Record forward sessions as logs (rewinds adjust progress without a log).
        if to > from {
            let log = WatchLog(date: .now, fromUnit: from, toUnit: to, note: note)
            log.title = title
            title.logs.append(log)
        }

        // First forward movement starts the title.
        if title.startedAt == nil && to > 0 {
            title.startedAt = .now
            if title.status == .planning { title.status = .current }
        }

        // Auto-complete on hitting the total.
        var justCompleted = false
        if let total = title.totalUnits, total > 0, to >= total, title.status != .completed {
            markCompleted(title)
            justCompleted = true
        } else if title.status == .completed, let total = title.totalUnits, total > 0, to < total {
            // Walked back below the end — return to current.
            title.status = .current
            title.finishedAt = nil
        }

        try? context.save()
        return justCompleted
    }

    /// Mark a title completed, snapping progress to total and stamping the date.
    static func markCompleted(_ title: Title) {
        if let total = title.totalUnits, total > 0 {
            title.progress = total
        }
        title.status = .completed
        if title.startedAt == nil { title.startedAt = .now }
        title.finishedAt = .now
    }

    /// Set a new status and keep dates coherent.
    static func setStatus(_ title: Title, to status: WatchStatus, in context: ModelContext) {
        title.status = status
        switch status {
        case .current:
            if title.startedAt == nil { title.startedAt = .now }
            title.finishedAt = nil
        case .completed:
            markCompleted(title)
        case .planning:
            title.startedAt = nil
            title.finishedAt = nil
        case .onHold, .dropped:
            title.finishedAt = nil
        }
        try? context.save()
    }

    /// Log a rewatch/reread: bump the counter and re-stamp finish.
    static func logRewatch(_ title: Title, in context: ModelContext) {
        title.rewatchCount = max(0, title.rewatchCount) + 1
        title.finishedAt = .now
        try? context.save()
    }
}
