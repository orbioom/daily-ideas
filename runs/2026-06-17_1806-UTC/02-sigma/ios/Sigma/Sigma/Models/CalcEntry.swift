import Foundation
import SwiftData

/// A single evaluated calculation, saved to the persistent history tape.
@Model
final class CalcEntry {
    @Attribute(.unique) var id: UUID
    var expression: String
    var result: String
    var timestamp: Date

    init(id: UUID = UUID(), expression: String, result: String, timestamp: Date = .now) {
        self.id = id
        self.expression = expression
        self.result = result
        self.timestamp = timestamp
    }
}
