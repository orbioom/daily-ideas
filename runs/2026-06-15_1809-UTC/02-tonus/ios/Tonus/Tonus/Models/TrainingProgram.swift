import Foundation
import SwiftData

/// A repeatable interval pattern: a sequence of squeeze / hold / relax phases, repeated for
/// `reps` per set across `sets`, with a rest between sets.
@Model
final class TrainingProgram {
    @Attribute(.unique) var id: UUID
    var name: String
    /// 1 = beginner, higher = more advanced.
    var level: Int
    var summary: String
    var contractSeconds: Int
    var holdSeconds: Int
    var relaxSeconds: Int
    var restSeconds: Int
    var reps: Int
    var sets: Int
    var isBuiltIn: Bool
    var sortIndex: Int

    init(id: UUID = UUID(),
         name: String,
         level: Int,
         summary: String,
         contractSeconds: Int,
         holdSeconds: Int,
         relaxSeconds: Int,
         restSeconds: Int,
         reps: Int,
         sets: Int,
         isBuiltIn: Bool,
         sortIndex: Int) {
        self.id = id
        self.name = name
        self.level = max(1, level)
        self.summary = summary
        self.contractSeconds = max(0, contractSeconds)
        self.holdSeconds = max(0, holdSeconds)
        self.relaxSeconds = max(0, relaxSeconds)
        self.restSeconds = max(0, restSeconds)
        self.reps = max(1, reps)
        self.sets = max(1, sets)
        self.isBuiltIn = isBuiltIn
        self.sortIndex = sortIndex
    }
}

extension TrainingProgram {
    /// A friendly band name for the program's level.
    var levelLabel: String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        default: return "Level \(level)"
        }
    }

    /// Active work seconds in a single rep (contract + hold + relax).
    var repSeconds: Int { contractSeconds + holdSeconds + relaxSeconds }
}
