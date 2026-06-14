import Foundation
import SwiftData

/// A single habit inside a routine. Either timed (counts down) or a checkbox.
@Model
final class RoutineStep {
    @Attribute(.unique) var id: UUID
    var title: String
    var iconName: String
    var kindRaw: String
    var durationSec: Int
    var note: String
    var sortOrder: Int
    var routine: Routine?

    init(id: UUID = UUID(),
         title: String,
         iconName: String = "circle.fill",
         kind: StepKind = .checkbox,
         durationSec: Int = 60,
         note: String = "",
         sortOrder: Int = 0,
         routine: Routine? = nil) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.kindRaw = kind.rawValue
        self.durationSec = durationSec
        self.note = note
        self.sortOrder = sortOrder
        self.routine = routine
    }

    var kind: StepKind {
        get { StepKind(rawValue: kindRaw) ?? .checkbox }
        set { kindRaw = newValue.rawValue }
    }

    /// Effective seconds the player should hold this step (0 for checkbox).
    var effectiveSeconds: Int {
        kind == .timed ? max(0, durationSec) : 0
    }
}
