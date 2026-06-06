import Foundation
import SwiftData

/// One attempt within a session. It references a `Climb` (preferred) but also
/// snapshots a canonical grade so analytics stay correct even for ad-hoc grades
/// logged without a full climb record, and survive a referenced climb's deletion.
@Model
final class Attempt {
    var id: UUID
    /// Position within the owning session (ascending).
    var order: Int
    /// Raw value of `Outcome`.
    var outcomeRaw: String
    /// Raw value of `GradeFamily` for the snapshotted grade.
    var gradeFamilyRaw: String
    /// Canonical grade rung snapshot — independent of the linked climb so a deleted
    /// climb doesn't corrupt history.
    var gradeIndex: Int
    var notes: String
    var createdAt: Date

    var session: Session?
    @Relationship var climb: Climb?

    init(id: UUID = UUID(),
         order: Int = 0,
         outcome: Outcome = .redpoint,
         gradeFamily: GradeFamily = .boulder,
         gradeIndex: Int = 0,
         notes: String = "",
         createdAt: Date = .now,
         climb: Climb? = nil) {
        self.id = id
        self.order = order
        self.outcomeRaw = outcome.rawValue
        self.gradeFamilyRaw = gradeFamily.rawValue
        self.gradeIndex = gradeIndex
        self.notes = notes
        self.createdAt = createdAt
        self.climb = climb
    }

    /// Tolerant accessor — unknown raw values fall back to `.fall`.
    var outcome: Outcome {
        get { Outcome(rawValue: outcomeRaw) ?? .fall }
        set { outcomeRaw = newValue.rawValue }
    }

    /// The grade family of this attempt's snapshotted grade.
    var gradeFamily: GradeFamily {
        GradeFamily(rawValue: gradeFamilyRaw) ?? .boulder
    }

    /// A display name for the attempted climb, falling back gracefully when the
    /// attempt was logged ad-hoc (no linked climb).
    var climbName: String {
        if let climb { return climb.displayName }
        return "Ad-hoc \(gradeFamily == .boulder ? "boulder" : "route")"
    }

    /// Render this attempt's snapshotted grade in the user's preferred systems.
    func gradeLabel(boulderSystem: GradeSystem, routeSystem: GradeSystem) -> String {
        GradeScale.display(index: gradeIndex,
                           family: gradeFamily,
                           boulderSystem: boulderSystem,
                           routeSystem: routeSystem)
    }
}
