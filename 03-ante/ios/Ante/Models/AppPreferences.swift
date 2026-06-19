import SwiftData
import Foundation

@Model final class AppPreferences {
    var hapticsEnabled: Bool
    var soundEnabled: Bool
    var winningScore: Int
    var animationsEnabled: Bool
    var showCardCount: Bool
    var isPro: Bool
    var cardBackColor: String

    init() {
        self.hapticsEnabled = true
        self.soundEnabled = true
        self.winningScore = 100
        self.animationsEnabled = true
        self.showCardCount = true
        self.isPro = false
        self.cardBackColor = "blue"
    }
}
