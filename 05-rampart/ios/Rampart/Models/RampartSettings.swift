import Foundation
import SwiftData

@Model
final class RampartSettings {
    var hasCompletedOnboarding: Bool
    var hasPro: Bool
    var soundEnabled: Bool
    var hapticEnabled: Bool

    init(hasCompletedOnboarding: Bool = false, hasPro: Bool = false, soundEnabled: Bool = true, hapticEnabled: Bool = true) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasPro = hasPro
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
    }
}
