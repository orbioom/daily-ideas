import Foundation
import SwiftData

/// Persisted result for a daily puzzle (one per calendar day).
@Model
final class DailyResult {
    /// "yyyy-MM-dd".
    @Attribute(.unique) var dateKey: String
    var seed: Int
    var timeSec: Int
    var foundCount: Int
    var total: Int
    var completed: Bool

    init(
        dateKey: String,
        seed: Int,
        timeSec: Int = 0,
        foundCount: Int = 0,
        total: Int = 0,
        completed: Bool = false
    ) {
        self.dateKey = dateKey
        self.seed = seed
        self.timeSec = timeSec
        self.foundCount = foundCount
        self.total = total
        self.completed = completed
    }
}
