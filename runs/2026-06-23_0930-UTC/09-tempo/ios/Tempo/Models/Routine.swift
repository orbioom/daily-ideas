import Foundation
import SwiftData

/// A reusable workout template (Push / Pull / Legs etc.). Stores an ordered list
/// of exercise references plus target set counts, used to seed a new workout fast.
@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var detail: String
    var colorHex: String
    var isBuiltIn: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.routine)
    var items: [RoutineItem]

    init(
        id: UUID = UUID(),
        name: String,
        detail: String = "",
        colorHex: String = "#EA7320",
        isBuiltIn: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.items = []
    }

    var orderedItems: [RoutineItem] {
        items.sorted { $0.order < $1.order }
    }
}

/// One exercise slot inside a routine, with a default target set count.
@Model
final class RoutineItem {
    @Attribute(.unique) var id: UUID
    var order: Int
    var targetSets: Int
    var targetReps: Int

    var routine: Routine?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int = 0,
        targetSets: Int = 3,
        targetReps: Int = 8,
        routine: Routine? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.targetSets = max(1, targetSets)
        self.targetReps = max(1, targetReps)
        self.routine = routine
        self.exercise = exercise
    }
}
