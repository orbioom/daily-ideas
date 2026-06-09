import Foundation
import SwiftData

/// A logged workout session. `actualSeconds` may be less than planned if the
/// user ended early. `feeling` is 0 when unrated, otherwise 1…5.
@Model
final class WorkoutSession {
    var date: Date
    var workoutName: String
    var category: String        // WorkoutCategory raw value
    var plannedSeconds: Int
    var actualSeconds: Int
    var roundsCompleted: Int
    var completed: Bool
    var feeling: Int            // 0 = unrated, 1…5
    var note: String

    init(date: Date = .now,
         workoutName: String,
         category: WorkoutCategory,
         plannedSeconds: Int,
         actualSeconds: Int,
         roundsCompleted: Int,
         completed: Bool,
         feeling: Int = 0,
         note: String = "") {
        self.date = date
        self.workoutName = workoutName
        self.category = category.rawValue
        self.plannedSeconds = max(0, plannedSeconds)
        self.actualSeconds = max(0, actualSeconds)
        self.roundsCompleted = max(0, roundsCompleted)
        self.completed = completed
        self.feeling = min(max(feeling, 0), 5)
        self.note = note
    }

    var workoutCategory: WorkoutCategory {
        WorkoutCategory(rawValue: category) ?? .fullBody
    }

    var minutes: Int { Int((Double(actualSeconds) / 60).rounded()) }
}
