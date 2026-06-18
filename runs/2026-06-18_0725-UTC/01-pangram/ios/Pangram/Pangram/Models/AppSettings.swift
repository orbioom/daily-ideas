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
    /// Require an explicit Enter tap to submit (off = submit on word completion gestures disabled anyway,
    /// but this also disables auto-clearing on rejected words for a beat).
    @AppStorage("confirmOnSubmit") var confirmOnSubmit = true
    /// Use a high-contrast, color-blind-safe palette for the honeycomb.
    @AppStorage("colorBlindSafe") var colorBlindSafe = false
    /// Show rank-up toast overlays as the player climbs the ladder.
    @AppStorage("showRankToasts") var showRankToasts = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}
