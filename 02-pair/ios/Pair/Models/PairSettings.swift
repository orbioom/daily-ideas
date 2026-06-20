import Foundation
import SwiftData

@Model
final class PairSettings {
    var hasCompletedOnboarding: Bool
    var hasPro: Bool
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var colorBlindMode: Bool

    init(
        hasCompletedOnboarding: Bool = false,
        hasPro: Bool = false,
        soundEnabled: Bool = true,
        hapticEnabled: Bool = true,
        colorBlindMode: Bool = false
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasPro = hasPro
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
        self.colorBlindMode = colorBlindMode
    }
}
