import Foundation
import SwiftData

/// A completed (or in-progress) training session, snapshotting program/day names.
@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var programName: String
    var dayName: String
    var durationSeconds: Int
    var notes: String
    var isComplete: Bool

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise]

    init(date: Date = .now,
         programName: String,
         dayName: String,
         durationSeconds: Int = 0,
         notes: String = "",
         isComplete: Bool = false) {
        self.id = UUID()
        self.date = date
        self.programName = programName
        self.dayName = dayName
        self.durationSeconds = max(durationSeconds, 0)
        self.notes = notes
        self.isComplete = isComplete
        self.exercises = []
    }

    var orderedExercises: [LoggedExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    /// Total volume: Σ weight × reps across all completed working sets.
    var totalVolumeKg: Double {
        orderedExercises.reduce(0) { acc, ex in
            acc + ex.sets.reduce(0) { inner, s in
                (s.isComplete && !s.isWarmup) ? inner + s.weightKg * Double(s.reps) : inner
            }
        }
    }

    var completedSetCount: Int {
        orderedExercises.reduce(0) { $0 + $1.sets.filter { $0.isComplete && !$0.isWarmup }.count }
    }
}
