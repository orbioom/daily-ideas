import Foundation
import SwiftData

/// A lightweight label that can be attached to many tasks (many-to-many).
@Model
final class Tag {
    var name: String
    var colorHex: String

    @Relationship var tasks: [TaskItem] = []

    init(name: String, colorHex: String = "4A7C8C") {
        self.name = name
        self.colorHex = colorHex
    }

    /// Count of active (not-done) tasks carrying this tag.
    var activeCount: Int { tasks.filter { !$0.isDone }.count }
}
