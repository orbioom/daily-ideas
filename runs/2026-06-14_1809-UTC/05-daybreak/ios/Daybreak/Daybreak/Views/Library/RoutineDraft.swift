import Foundation

/// Value-type working copy of a routine while editing (so Cancel discards cleanly).
struct RoutineDraft {
    var name: String = ""
    var timeOfDay: TimeOfDay = .morning
    var colorHex: String = "C77E22"
    var iconName: String = "sunrise.fill"
    var steps: [StepDraft] = []

    init() {}

    init(routine: Routine) {
        name = routine.name
        timeOfDay = routine.timeOfDay
        colorHex = routine.colorHex
        iconName = routine.iconName
        steps = routine.orderedSteps.map { StepDraft(step: $0) }
    }
}

/// Value-type working copy of a step.
struct StepDraft: Identifiable, Equatable {
    let id: UUID
    var title: String
    var iconName: String
    var kind: StepKind
    var durationSec: Int
    var note: String

    init(id: UUID = UUID(),
         title: String = "",
         iconName: String = "circle.fill",
         kind: StepKind = .checkbox,
         durationSec: Int = 60,
         note: String = "") {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.kind = kind
        self.durationSec = durationSec
        self.note = note
    }

    init(step: RoutineStep) {
        id = step.id
        title = step.title
        iconName = step.iconName
        kind = step.kind
        durationSec = max(0, step.durationSec)
        note = step.note
    }
}
