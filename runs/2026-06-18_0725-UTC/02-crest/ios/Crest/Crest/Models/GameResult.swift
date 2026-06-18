import Foundation
import SwiftData

/// A completed game record. Primary persisted collection (drives Stats & streaks).
@Model
final class GameResult {
    @Attribute(.unique) var id: UUID
    var layoutRaw: String
    var won: Bool
    var score: Int
    var durationSec: Double
    var cardsCleared: Int
    var longestCombo: Int
    var dealNumber: Int
    var isDaily: Bool
    var date: Date

    init(
        id: UUID = UUID(),
        layoutRaw: String,
        won: Bool,
        score: Int,
        durationSec: Double,
        cardsCleared: Int,
        longestCombo: Int,
        dealNumber: Int,
        isDaily: Bool,
        date: Date
    ) {
        self.id = id
        self.layoutRaw = layoutRaw
        self.won = won
        self.score = score
        self.durationSec = durationSec
        self.cardsCleared = cardsCleared
        self.longestCombo = longestCombo
        self.dealNumber = dealNumber
        self.isDaily = isDaily
        self.date = date
    }

    var layout: BoardLayout { BoardLayout(rawValue: layoutRaw) ?? .threePeaks }
}
