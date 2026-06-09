import Foundation
import SwiftData

/// A checklist item nested under a `TaskItem`. Ordered by `order`.
@Model
final class Subtask {
    var title: String
    var isDone: Bool
    var order: Int

    var task: TaskItem?

    init(title: String, isDone: Bool = false, order: Int = 0) {
        self.title = title
        self.isDone = isDone
        self.order = order
    }
}
