import Foundation
import SwiftData

@Model
final class DominoSettings {
    var id: UUID
    var difficulty: String        // "easy", "medium", "hard"
    var matchPointTarget: Int     // 50, 100, 150
    var hapticsEnabled: Bool
    var hasCompletedOnboarding: Bool
    var tileStyle: String         // "classic", "modern", "dark"
    var showAIHand: Bool          // debug option

    init(
        id: UUID = UUID(),
        difficulty: String = "medium",
        matchPointTarget: Int = 100,
        hapticsEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false,
        tileStyle: String = "classic",
        showAIHand: Bool = false
    ) {
        self.id = id
        self.difficulty = difficulty
        self.matchPointTarget = matchPointTarget
        self.hapticsEnabled = hapticsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.tileStyle = tileStyle
        self.showAIHand = showAIHand
    }
}
