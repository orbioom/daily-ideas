import Foundation
import SwiftData

/// A recorded run of a routine, written to the History log on completion (or when a
/// run is ended early). Captures enough to summarise without re-deriving from segments.
@Model
final class Session {
    var id: UUID
    var startedAt: Date
    /// When the run finished (completed or stopped early).
    var endedAt: Date
    /// Total seconds the engine actually ran (excludes paused time).
    var activeSeconds: Int
    /// Seconds spent in `work` segments during this run.
    var workSeconds: Int
    /// Number of timeline steps completed.
    var completedSteps: Int
    /// Total timeline steps the routine contained at run time.
    var totalSteps: Int
    /// True when every step was reached (a full run rather than an early stop).
    var finishedFully: Bool
    /// Snapshot of the routine name at run time (survives a later rename/delete display-wise).
    var routineNameSnapshot: String

    var routine: Routine?

    init(id: UUID = UUID(),
         startedAt: Date,
         endedAt: Date,
         activeSeconds: Int,
         workSeconds: Int,
         completedSteps: Int,
         totalSteps: Int,
         finishedFully: Bool,
         routineNameSnapshot: String) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.activeSeconds = max(0, activeSeconds)
        self.workSeconds = max(0, workSeconds)
        self.completedSteps = max(0, completedSteps)
        self.totalSteps = max(0, totalSteps)
        self.finishedFully = finishedFully
        self.routineNameSnapshot = routineNameSnapshot
    }

    /// Fraction of the routine completed, clamped to 0...1.
    var completionFraction: Double {
        guard totalSteps > 0 else { return 0 }
        return min(1, max(0, Double(completedSteps) / Double(totalSteps)))
    }
}
