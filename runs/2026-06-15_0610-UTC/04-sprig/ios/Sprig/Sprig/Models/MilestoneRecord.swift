import Foundation
import SwiftData

/// A child's progress on one milestone from the curated CDC catalog, keyed by `milestoneKey`.
/// A record exists only once a milestone has been marked achieved (achievedDate set); absence
/// means "not yet". We keep the row even if un-achieved later, with achievedDate = nil.
@Model
final class MilestoneRecord {
    @Attribute(.unique) var id: UUID
    var milestoneKey: String
    var achievedDate: Date?
    var child: Child?

    init(id: UUID = UUID(),
         milestoneKey: String,
         achievedDate: Date? = nil,
         child: Child? = nil) {
        self.id = id
        self.milestoneKey = milestoneKey
        self.achievedDate = achievedDate
        self.child = child
    }

    var isAchieved: Bool { achievedDate != nil }

    /// The catalog definition this record points to, if it still exists.
    var milestone: Milestone? { MilestoneCatalog.byKey[milestoneKey] }
}
