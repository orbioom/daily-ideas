import Foundation
import SwiftData

@Model final class PebbleStats {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var gamesDrawn: Int = 0
    var highScore: Int = 0
    var longestWinStreak: Int = 0
    var currentStreak: Int = 0
    init() {}
}

@Model final class PebbleSettings {
    var difficulty: Int = 1      // 0 = Easy, 1 = Medium, 2 = Hard
    var stonesPerPit: Int = 4
    var hapticFeedback: Bool = true
    var soundEnabled: Bool = true
    init() {}
}

@Model final class PebbleOnboarding {
    var completed: Bool = false
    init() {}
}
