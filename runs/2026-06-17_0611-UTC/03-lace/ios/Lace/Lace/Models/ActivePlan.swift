import Foundation
import SwiftData

/// The user's current enrollment. There is at most one; switching plans
/// replaces it. Tracks where the runner is in the schedule.
@Model
final class ActivePlan {
    @Attribute(.unique) var id: UUID
    var planId: String
    var startDate: Date
    var currentWeek: Int          // 1-based
    var currentSessionIndex: Int  // 0-based within the week

    init(id: UUID = UUID(),
         planId: String,
         startDate: Date = Date(),
         currentWeek: Int = 1,
         currentSessionIndex: Int = 0) {
        self.id = id
        self.planId = planId
        self.startDate = startDate
        self.currentWeek = max(1, currentWeek)
        self.currentSessionIndex = max(0, currentSessionIndex)
    }
}
