import Foundation
import SwiftData

/// One step in a bake's timeline. Carries its own planned duration so the schedule
/// engine can lay clock times across the whole bake from a single anchor.
@Model
final class BakeStep {
    var id: UUID
    /// Position in the timeline (0-based). The engine sorts and accumulates by this.
    var order: Int
    /// Raw value of `StepKind` for tolerant decoding.
    var kindRaw: String
    /// A short, editable label (defaults to the kind's title).
    var label: String
    /// Planned duration in minutes. Guarded to be non-negative by the engine.
    var plannedMinutes: Int
    /// Optional detail shown under the step.
    var detail: String

    /// Owning bake. Optional so SwiftData can manage the inverse relationship.
    var bake: Bake?

    init(id: UUID = UUID(),
         order: Int,
         kind: StepKind,
         label: String = "",
         plannedMinutes: Int? = nil,
         detail: String = "") {
        self.id = id
        self.order = order
        self.kindRaw = kind.rawValue
        self.label = label.isEmpty ? kind.title : label
        self.plannedMinutes = max(0, plannedMinutes ?? kind.defaultMinutes)
        self.detail = detail
    }

    /// Tolerant accessor — falls back to `.custom` for any unknown raw value.
    var kind: StepKind {
        get { StepKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }
}
