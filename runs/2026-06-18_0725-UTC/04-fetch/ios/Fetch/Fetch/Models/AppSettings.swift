import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}

@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("clickerSoundEnabled") var clickerSoundEnabled = true
    @AppStorage("dailyGoalMinutes") var dailyGoalMinutes = 15
    @AppStorage("defaultSessionMinutes") var defaultSessionMinutes = 5

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    /// Clamp helpers so persisted values always stay sane.
    var dailyGoalClamped: Int { min(120, max(5, dailyGoalMinutes)) }
    var defaultSessionClamped: Int { min(30, max(1, defaultSessionMinutes)) }
}
