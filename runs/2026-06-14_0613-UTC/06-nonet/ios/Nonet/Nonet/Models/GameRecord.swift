import Foundation
import SwiftData

/// A finished game's history entry, used to compute stats and charts.
@Model
final class GameRecord {
    @Attribute(.unique) var id: UUID
    var difficultyRaw: Int
    var timeSec: Int
    var date: Date
    var won: Bool
    var isDaily: Bool
    var mistakes: Int
    var hintsUsed: Int
    var dateKey: String   // "yyyyMMdd" of completion, for the solved-days heatmap

    init(id: UUID = UUID(),
         difficulty: Difficulty,
         timeSec: Int,
         date: Date = Date(),
         won: Bool,
         isDaily: Bool,
         mistakes: Int,
         hintsUsed: Int = 0,
         dateKey: String = "") {
        self.id = id
        self.difficultyRaw = difficulty.rawValue
        self.timeSec = timeSec
        self.date = date
        self.won = won
        self.isDaily = isDaily
        self.mistakes = mistakes
        self.hintsUsed = hintsUsed
        self.dateKey = dateKey
    }

    var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .easy }
}
