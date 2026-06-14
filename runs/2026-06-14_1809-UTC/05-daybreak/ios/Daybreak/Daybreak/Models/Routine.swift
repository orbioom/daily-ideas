import Foundation
import SwiftData

/// A named chain of small habits, run step-by-step in the guided player.
@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var timeOfDayRaw: String
    var colorHex: String
    var iconName: String
    var sortOrder: Int
    var dateAdded: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineStep.routine)
    var steps: [RoutineStep]

    init(id: UUID = UUID(),
         name: String,
         timeOfDay: TimeOfDay = .morning,
         colorHex: String = "C77E22",
         iconName: String = "sun.max.fill",
         sortOrder: Int = 0,
         dateAdded: Date = Date(),
         steps: [RoutineStep] = []) {
        self.id = id
        self.name = name
        self.timeOfDayRaw = timeOfDay.rawValue
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.dateAdded = dateAdded
        self.steps = steps
    }

    var timeOfDay: TimeOfDay {
        get { TimeOfDay(rawValue: timeOfDayRaw) ?? .anytime }
        set { timeOfDayRaw = newValue.rawValue }
    }

    /// Steps in their stored order.
    var orderedSteps: [RoutineStep] {
        steps.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Total seconds across timed steps (checkbox steps contribute 0).
    var totalSeconds: Int {
        steps.reduce(0) { acc, step in
            acc + (step.kind == .timed ? max(0, step.durationSec) : 0)
        }
    }

    var estimatedMinutes: Int {
        max(1, Int((Double(totalSeconds) / 60).rounded()))
    }
}
