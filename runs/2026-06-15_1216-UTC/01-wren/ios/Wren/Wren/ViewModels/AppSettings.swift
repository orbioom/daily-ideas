import SwiftUI

/// User preferences persisted via @AppStorage. Exposed as an ObservableObject so
/// views can read/write a single shared instance from the environment.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("dailyGoalTarget") var dailyGoalTarget = 3
    @AppStorage("remindersEnabled") var remindersEnabled = false
    @AppStorage("isPro") var isPro = false

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    /// Convenience for gated haptics throughout the app.
    func haptic(_ kind: Haptics.Kind) {
        Haptics.play(kind, enabled: hapticsEnabled)
    }
}
