import Foundation
import SwiftData

/// Persisted outcome of a daily puzzle, keyed by calendar date (yyyy-MM-dd).
@Model
final class DailyResult {
    @Attribute(.unique) var dateKey: String
    var completed: Bool
    var stars: Int
    var completedAt: Date?

    init(dateKey: String, completed: Bool = false, stars: Int = 0, completedAt: Date? = nil) {
        self.dateKey = dateKey
        self.completed = completed
        self.stars = stars
        self.completedAt = completedAt
    }
}
