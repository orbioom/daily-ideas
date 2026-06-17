import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        self == .system ? nil : (self == .light ? .light : .dark)
    }
}

@MainActor final class AppSettings: ObservableObject {
    /// Haptic feedback toggle.
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    /// Sound effects toggle (gates the lightweight sound feedback layer).
    @AppStorage("soundEnabled") var soundEnabled = true
    /// Hard mode — disables the first-letter hint and reduces hint refills.
    @AppStorage("hardMode") var hardMode = false
    /// Show a textual list of found words under the grid.
    @AppStorage("showFoundList") var showFoundList = true
    /// Appearance: System / Light / Dark.
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
