import Foundation
import SwiftData

/// A top-level area of responsibility (e.g. Personal, Work) that contains
/// projects. Deleting an area nullifies its projects' `area` link.
@Model
final class Area {
    var name: String
    var colorHex: String
    var order: Int

    @Relationship(inverse: \Project.area) var projects: [Project] = []

    init(name: String, colorHex: String = "4A7C8C", order: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.order = order
    }

    /// Sorted active projects (not yet complete), by their `order`.
    var activeProjects: [Project] {
        projects.filter { !$0.isComplete }.sorted { $0.order < $1.order }
    }

    /// Roll-up of task progress across all projects in this area.
    var rollup: (done: Int, total: Int) {
        var done = 0, total = 0
        for project in projects {
            let p = project.progress
            done += p.done
            total += p.total
        }
        return (done, total)
    }
}
