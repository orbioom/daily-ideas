import Foundation
import SwiftData

/// A persisted dice-roll history entry.
@Model
final class DiceLog {
    var id: UUID = UUID()
    var expression: String = ""
    var total: Int = 0
    var breakdown: String = ""
    var label: String = ""
    var createdAt: Date = Date()

    init(expression: String, total: Int, breakdown: String, label: String = "") {
        self.id = UUID()
        self.expression = expression
        self.total = total
        self.breakdown = breakdown
        self.label = label
        self.createdAt = Date()
    }
}
