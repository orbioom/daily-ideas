import Foundation
import SwiftData

@Model
class ScrawlSettings {
    var id: UUID
    var timerSeconds: Int
    var roundCount: Int
    var hapticsEnabled: Bool
    var hasCompletedOnboarding: Bool

    init(
        id: UUID = UUID(),
        timerSeconds: Int = 60,
        roundCount: Int = 3,
        hapticsEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.timerSeconds = timerSeconds
        self.roundCount = roundCount
        self.hapticsEnabled = hapticsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
