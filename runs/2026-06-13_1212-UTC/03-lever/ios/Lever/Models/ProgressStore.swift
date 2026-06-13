import Foundation
import SwiftData

/// Helpers for reading and lazily creating per-exercise progress records.
/// Kept free-function style so views can call them with a `ModelContext`.
enum ProgressStore {

    /// Return the progress record for an exercise, creating it if needed.
    static func progress(for exerciseID: String,
                         in existing: [ExerciseProgress],
                         context: ModelContext) -> ExerciseProgress {
        if let found = existing.first(where: { $0.exerciseID == exerciseID }) {
            return found
        }
        let created = ExerciseProgress(exerciseID: exerciseID)
        context.insert(created)
        try? context.save()
        return created
    }

    /// Look up an existing progress record without creating one.
    static func find(_ exerciseID: String, in existing: [ExerciseProgress]) -> ExerciseProgress? {
        existing.first { $0.exerciseID == exerciseID }
    }
}
