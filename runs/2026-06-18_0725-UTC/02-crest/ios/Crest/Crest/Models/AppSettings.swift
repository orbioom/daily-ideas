import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    /// King↔Ace wrap-around adjacency. Default ON per spec.
    @AppStorage("wrapAround") var wrapAround = true
    /// Play a soft click when drawing / clearing.
    @AppStorage("drawSound") var drawSound = true
    /// Mirror the stock & controls for left-handed play.
    @AppStorage("leftHanded") var leftHanded = false
    /// Selected felt table theme (Pro themes gated at the UI layer).
    @AppStorage("feltTheme") var feltThemeRaw = FeltTheme.classic.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var feltTheme: FeltTheme {
        get { FeltTheme(rawValue: feltThemeRaw) ?? .classic }
        set { feltThemeRaw = newValue.rawValue }
    }
}
