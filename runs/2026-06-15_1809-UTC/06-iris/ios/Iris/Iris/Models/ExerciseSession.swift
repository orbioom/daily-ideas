import Foundation
import SwiftData

/// A completed (or partly completed) guided eye-exercise routine.
@Model
final class ExerciseSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var routineName: String
    var durationSeconds: Int
    var exercisesCompleted: Int

    init(id: UUID = UUID(),
         date: Date = .now,
         routineName: String = "",
         durationSeconds: Int = 0,
         exercisesCompleted: Int = 0) {
        self.id = id
        self.date = date
        self.routineName = routineName
        self.durationSeconds = durationSeconds
        self.exercisesCompleted = exercisesCompleted
    }

    var minutes: Double {
        Double(max(0, durationSeconds)) / 60.0
    }
}
