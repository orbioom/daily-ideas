import SwiftUI

/// App appearance preference.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Tile back / theme color choices. Some are Pro-only.
enum TileTheme: String, CaseIterable, Identifiable {
    case lacquer    // deep red (default, free)
    case ivory      // soft ivory (free)
    case jade       // green (pro)
    case midnight   // dark blue (pro)

    var id: String { rawValue }
    var label: String {
        switch self {
        case .lacquer: return "Lacquer Red"
        case .ivory: return "Ivory"
        case .jade: return "Jade"
        case .midnight: return "Midnight"
        }
    }
    var isPro: Bool {
        switch self {
        case .lacquer, .ivory: return false
        case .jade, .midnight: return true
        }
    }
    /// The tile back / accent tint for this theme.
    var backColor: Color {
        switch self {
        case .lacquer: return Color.dyn(0xB5342C, 0x8C2620)
        case .ivory: return Color.dyn(0xE9DDC6, 0xB7A582)
        case .jade: return Color.dyn(0x2E7D5B, 0x1F5C42)
        case .midnight: return Color.dyn(0x2B3A66, 0x1B264A)
        }
    }
}

/// Centralized, persisted user preferences. `@AppStorage` keeps each one in
/// UserDefaults; SwiftData holds the real game data.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue
    @AppStorage("showFreeHints") var showFreeHints: Bool = true
    @AppStorage("confirmOnRestart") var confirmOnRestart: Bool = true
    @AppStorage("tileTheme") var tileThemeRaw: String = TileTheme.lacquer.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    /// Effective tile theme — falls back to a free theme if a Pro theme is set
    /// while not Pro.
    func tileTheme(isPro: Bool) -> TileTheme {
        let t = TileTheme(rawValue: tileThemeRaw) ?? .lacquer
        if t.isPro && !isPro { return .lacquer }
        return t
    }
}
