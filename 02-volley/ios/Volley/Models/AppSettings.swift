import Foundation
import SwiftData

@Model
final class AppSettings {
    var hapticsEnabled: Bool
    var safeMode: Bool
    var hasPro: Bool
    var hasCompletedOnboarding: Bool
    var defaultQuestionCount: Int

    init(
        hapticsEnabled: Bool = true,
        safeMode: Bool = false,
        hasPro: Bool = false,
        hasCompletedOnboarding: Bool = false,
        defaultQuestionCount: Int = 20
    ) {
        self.hapticsEnabled = hapticsEnabled
        self.safeMode = safeMode
        self.hasPro = hasPro
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.defaultQuestionCount = defaultQuestionCount
    }
}
