import Foundation
import SwiftData

/// A single climb: a named gym problem or an outdoor route/boulder. The grade is
/// stored canonically as `(gradeFamilyRaw, gradeIndex)` so analytics can sort and
/// aggregate regardless of which display system the user prefers.
@Model
final class Climb {
    var id: UUID
    /// Optional — many gym problems are unnamed ("the blue V4").
    var name: String
    /// Raw value of `Discipline`.
    var disciplineRaw: String
    /// Raw value of `GradeFamily` — which canonical ladder `gradeIndex` indexes into.
    var gradeFamilyRaw: String
    /// Canonical rung on the family's ladder. Bounds-checked on read via `gradeScale`.
    var gradeIndex: Int
    /// Optional hold-color index for gym problems (-1 means "no color set").
    var colorIndex: Int
    /// Optional set date for gym problems.
    var setDate: Date?
    var notes: String
    /// Whether this is an active project the climber is working toward.
    var isProject: Bool
    var createdAt: Date

    @Relationship var location: Location?

    /// Attempts that reference this climb (cleared if the climb is deleted).
    @Relationship(inverse: \Attempt.climb)
    var attempts: [Attempt]

    init(id: UUID = UUID(),
         name: String = "",
         discipline: Discipline = .boulder,
         gradeIndex: Int = 0,
         colorIndex: Int = -1,
         setDate: Date? = nil,
         notes: String = "",
         isProject: Bool = false,
         createdAt: Date = .now,
         location: Location? = nil) {
        self.id = id
        self.name = name
        self.disciplineRaw = discipline.rawValue
        self.gradeFamilyRaw = discipline.family.rawValue
        self.gradeIndex = gradeIndex
        self.colorIndex = colorIndex
        self.setDate = setDate
        self.notes = notes
        self.isProject = isProject
        self.createdAt = createdAt
        self.location = location
        self.attempts = []
    }

    /// Tolerant accessor — unknown raw values fall back to `.boulder`.
    var discipline: Discipline {
        get { Discipline(rawValue: disciplineRaw) ?? .boulder }
        set {
            disciplineRaw = newValue.rawValue
            gradeFamilyRaw = newValue.family.rawValue
        }
    }

    /// The grade family this climb is graded against.
    var gradeFamily: GradeFamily {
        GradeFamily(rawValue: gradeFamilyRaw) ?? discipline.family
    }

    /// A display name that is never empty — falls back to the grade family label.
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unnamed \(discipline.title)" : trimmed
    }

    /// Whether a hold color has been assigned.
    var hasColor: Bool { colorIndex >= 0 }

    /// Render this climb's grade in the user's preferred systems.
    func gradeLabel(boulderSystem: GradeSystem, routeSystem: GradeSystem) -> String {
        GradeScale.display(index: gradeIndex,
                           family: gradeFamily,
                           boulderSystem: boulderSystem,
                           routeSystem: routeSystem)
    }

    /// Sends recorded against this climb.
    var sendCount: Int { attempts.filter { $0.outcome.isSend }.count }

    /// Whether this climb has at least one recorded send.
    var isSent: Bool { attempts.contains { $0.outcome.isSend } }
}
