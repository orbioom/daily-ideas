import Foundation
import SwiftData

/// A reusable workout: a list of ordered items performed for a number of rounds,
/// with configurable rest between exercises and between rounds. Built-in
/// workouts seed on first launch; users build their own in the Build tab.
@Model
final class Workout {
    var name: String
    var summary: String
    var categoryRaw: String
    var difficultyRaw: String
    var rounds: Int
    var restBetweenExercisesSec: Int
    var restBetweenRoundsSec: Int
    var isBuiltIn: Bool
    var sortIndex: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutItem.workout)
    var items: [WorkoutItem]

    init(name: String,
         summary: String = "",
         category: WorkoutCategory,
         difficulty: Difficulty = .moderate,
         rounds: Int = 1,
         restBetweenExercisesSec: Int = 15,
         restBetweenRoundsSec: Int = 60,
         isBuiltIn: Bool = false,
         sortIndex: Int = 0,
         items: [WorkoutItem] = []) {
        self.name = name
        self.summary = summary
        self.categoryRaw = category.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.rounds = min(max(rounds, 1), 20)
        self.restBetweenExercisesSec = min(max(restBetweenExercisesSec, 0), 300)
        self.restBetweenRoundsSec = min(max(restBetweenRoundsSec, 0), 600)
        self.isBuiltIn = isBuiltIn
        self.sortIndex = sortIndex
        self.createdAt = .now
        self.items = items
    }

    var category: WorkoutCategory {
        get { WorkoutCategory(rawValue: categoryRaw) ?? .fullBody }
        set { categoryRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .moderate }
        set { difficultyRaw = newValue.rawValue }
    }

    /// Items sorted by their stored order — the source of truth for sequencing.
    var orderedItems: [WorkoutItem] {
        items.sorted { $0.order < $1.order }
    }

    var estimatedSeconds: Int {
        WorkoutEngine.estimatedSeconds(for: self)
    }

    var subtitle: String {
        var parts = ["\(orderedItems.count) moves"]
        if rounds > 1 { parts.append("\(rounds) rounds") }
        parts.append(Format.estimate(estimatedSeconds))
        return parts.joined(separator: " · ")
    }
}
