import Foundation
import SwiftData

/// A small subtask inside a time block. Ordered by `order`.
@Model
final class ChecklistItem {
    var title: String
    var isDone: Bool
    var order: Int
    var block: TimeBlock?

    init(title: String, isDone: Bool = false, order: Int = 0) {
        self.title = title
        self.isDone = isDone
        self.order = order
    }
}
