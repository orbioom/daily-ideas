import Foundation
import SwiftData

/// Persisted completion record for a single level. One per level id.
@Model
final class LevelProgress {
    @Attribute(.unique) var id: String
    var levelID: String
    var completed: Bool
    var starsEarned: Int
    var bonusFoundCount: Int
    var completedAt: Date?

    init(levelID: String,
         completed: Bool = false,
         starsEarned: Int = 0,
         bonusFoundCount: Int = 0,
         completedAt: Date? = nil) {
        self.id = levelID
        self.levelID = levelID
        self.completed = completed
        self.starsEarned = starsEarned
        self.bonusFoundCount = bonusFoundCount
        self.completedAt = completedAt
    }
}
