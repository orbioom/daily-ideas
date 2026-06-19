import Foundation
import SwiftData

@Model
final class GameResult {
    var date: Date
    var won: Bool
    var score: Int
    var moves: Int
    var duration: TimeInterval
    var isDaily: Bool

    init(date: Date = .now, won: Bool, score: Int, moves: Int, duration: TimeInterval, isDaily: Bool = false) {
        self.date = date
        self.won = won
        self.score = score
        self.moves = moves
        self.duration = duration
        self.isDaily = isDaily
    }
}

@Model
final class AppPreferences {
    var hasSeenOnboarding: Bool
    var hapticEnabled: Bool
    var showCardNumbers: Bool
    var theme: String  // "classic", "midnight", "forest"
    var isPro: Bool

    init() {
        hasSeenOnboarding = false
        hapticEnabled = true
        showCardNumbers = false
        theme = "classic"
        isPro = false
    }
}
