import Foundation
import SwiftData

@Model final class PegStats {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var highScore: Int = 0
    var totalPoints: Int = 0
    var longestWinStreak: Int = 0
    var currentStreak: Int = 0
    init() {}
}

@Model final class PegSettings {
    var difficulty: Int = 1  // 0=easy 1=medium 2=hard
    var showHints: Bool = true
    var hapticFeedback: Bool = true
    var soundEnabled: Bool = true
    init() {}
}

@Model final class PegOnboarding {
    var completed: Bool = false
    init() {}
}
