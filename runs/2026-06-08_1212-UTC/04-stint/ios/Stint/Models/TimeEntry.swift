import Foundation
import SwiftData

/// A tracked block of time. A nil `end` means the timer is still running.
@Model
final class TimeEntry {
    var id: UUID
    var detail: String
    var start: Date
    var end: Date?
    var createdAt: Date
    var project: Project?

    init(
        id: UUID = UUID(),
        detail: String = "",
        start: Date = .now,
        end: Date? = nil,
        createdAt: Date = .now,
        project: Project? = nil
    ) {
        self.id = id
        self.detail = detail
        self.start = start
        self.end = end
        self.createdAt = createdAt
        self.project = project
    }

    var isRunning: Bool { end == nil }

    /// Elapsed seconds. For a running entry, measured to `now`. Never negative.
    func seconds(now: Date = .now) -> TimeInterval {
        let finish = end ?? now
        return max(0, finish.timeIntervalSince(start))
    }

    func hours(now: Date = .now) -> Double { seconds(now: now) / 3600 }

    /// Billable earnings for this entry given its project's effective rate.
    func earnings(now: Date = .now) -> Double {
        guard let project, project.billable else { return 0 }
        return hours(now: now) * project.effectiveRate
    }
}
