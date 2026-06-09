import Foundation
import SwiftData

/// A project groups related tasks and tracks completion. It can live inside an
/// `Area`. Deleting a project nullifies its tasks' `project` link (tasks remain).
@Model
final class Project {
    var name: String
    var colorHex: String
    var notes: String
    var isComplete: Bool
    var order: Int

    var area: Area?

    @Relationship(inverse: \TaskItem.project) var tasks: [TaskItem] = []

    init(name: String,
         colorHex: String = "4A7C8C",
         notes: String = "",
         isComplete: Bool = false,
         order: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.notes = notes
        self.isComplete = isComplete
        self.order = order
    }

    /// Active (not-done) tasks only, the ones the user still has to do.
    var activeTasks: [TaskItem] { tasks.filter { !$0.isDone } }

    /// Completion progress as (done, total). Total counts all attached tasks.
    var progress: (done: Int, total: Int) {
        let total = tasks.count
        let done = tasks.filter { $0.isDone }.count
        return (done, total)
    }

    /// Fraction 0…1 of completed tasks. Guards empty projects.
    var progressFraction: Double {
        let p = progress
        guard p.total > 0 else { return 0 }
        return Double(p.done) / Double(p.total)
    }
}
