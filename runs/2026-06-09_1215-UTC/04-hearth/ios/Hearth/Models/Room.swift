import Foundation
import SwiftData

/// A space in the home — Kitchen, Bathroom, etc. Owns a set of recurring
/// cleaning tasks. Deleting a room cascades to its tasks (but not its
/// `CompletionLog` history, which is kept independently so stats survive).
@Model
final class Room {
    var name: String
    var symbol: String          // SF Symbol name
    var colorIndex: Int         // maps to a Brand accent via Palette
    var sortIndex: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CleaningTask.room)
    var tasks: [CleaningTask]

    init(name: String,
         symbol: String = "house",
         colorIndex: Int = 0,
         sortIndex: Int = 0,
         tasks: [CleaningTask] = []) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.symbol = symbol
        self.colorIndex = max(0, colorIndex)
        self.sortIndex = sortIndex
        self.createdAt = .now
        self.tasks = tasks
    }

    /// Active tasks belonging to this room, in display order.
    var activeTasks: [CleaningTask] {
        tasks.filter { $0.isActive }.sorted { $0.sortIndex < $1.sortIndex }
    }

    /// All tasks in display order (active + paused).
    var sortedTasks: [CleaningTask] {
        tasks.sorted { $0.sortIndex < $1.sortIndex }
    }
}
