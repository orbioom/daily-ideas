import Foundation
import SwiftData

/// A record of one guided run (completed or abandoned). Snapshots the name in
/// case the source routine is later renamed or deleted.
@Model
final class RoutineRun {
    @Attribute(.unique) var id: UUID
    var date: Date
    var routineName: String
    var routineRef: Routine?
    var completedSteps: Int
    var totalSteps: Int
    var durationSec: Int

    init(id: UUID = UUID(),
         date: Date = Date(),
         routineName: String,
         routineRef: Routine? = nil,
         completedSteps: Int,
         totalSteps: Int,
         durationSec: Int) {
        self.id = id
        self.date = date
        self.routineName = routineName
        self.routineRef = routineRef
        self.completedSteps = max(0, completedSteps)
        self.totalSteps = max(0, totalSteps)
        self.durationSec = max(0, durationSec)
    }

    /// Fraction of steps completed, guarded against zero totals.
    var completionFraction: Double {
        guard totalSteps > 0 else { return 0 }
        return min(1, Double(completedSteps) / Double(totalSteps))
    }

    var minutes: Int { durationSec / 60 }
}
