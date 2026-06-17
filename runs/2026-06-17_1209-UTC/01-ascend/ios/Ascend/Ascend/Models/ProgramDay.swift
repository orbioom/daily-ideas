import Foundation
import SwiftData

/// A single training day within a program (e.g. "Workout A").
@Model
final class ProgramDay {
    @Attribute(.unique) var id: UUID
    var name: String
    var order: Int
    var program: Program?

    @Relationship(deleteRule: .cascade, inverse: \ProgramExercise.day)
    var exercises: [ProgramExercise]

    init(name: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.exercises = []
    }

    var orderedExercises: [ProgramExercise] {
        exercises.sorted { $0.order < $1.order }
    }
}
