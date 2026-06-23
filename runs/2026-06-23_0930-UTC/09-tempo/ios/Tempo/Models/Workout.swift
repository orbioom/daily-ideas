import Foundation
import SwiftData

/// A training session. Owns its logged sets (cascade delete). A workout is "active"
/// while `finishedAt` is nil; finishing stamps the date.
@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var title: String
    var startedAt: Date
    var finishedAt: Date?
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.workout)
    var sets: [SetEntry]

    init(
        id: UUID = UUID(),
        title: String = "Workout",
        startedAt: Date = .now,
        finishedAt: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.notes = notes
        self.sets = []
    }

    var isActive: Bool { finishedAt == nil }

    /// Duration in seconds (live if active).
    var duration: TimeInterval {
        (finishedAt ?? .now).timeIntervalSince(startedAt)
    }

    /// Only sets the user marked complete count toward totals.
    var completedSets: [SetEntry] { sets.filter { $0.isCompleted } }

    /// Total volume = sum of weight × reps over completed working sets.
    var totalVolume: Double {
        completedSets.reduce(0) { $0 + $1.volume }
    }

    var totalReps: Int {
        completedSets.reduce(0) { $0 + $1.reps }
    }

    /// Distinct exercises present in this workout, ordered by first appearance.
    var exercises: [Exercise] {
        var seen = Set<UUID>()
        var result: [Exercise] = []
        for s in sets.sorted(by: { $0.order < $1.order }) {
            if let ex = s.exercise, !seen.contains(ex.id) {
                seen.insert(ex.id)
                result.append(ex)
            }
        }
        return result
    }

    /// Sets for a given exercise, ordered.
    func sets(for exercise: Exercise) -> [SetEntry] {
        sets.filter { $0.exercise?.id == exercise.id }
            .sorted { $0.order < $1.order }
    }
}
