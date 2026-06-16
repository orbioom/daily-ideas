import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// App-wide preferences persisted via @AppStorage.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("defaultDifficulty") var defaultDifficultyRaw = Difficulty.easy.rawValue
    @AppStorage("allowDiagonals") var allowDiagonals = true
    @AppStorage("allowReverse") var allowReverse = true
    @AppStorage("highlightTheme") var highlightThemeRaw = HighlightTheme.terracotta.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultDifficulty: Difficulty {
        get { Difficulty(rawValue: defaultDifficultyRaw) ?? .easy }
        set { defaultDifficultyRaw = newValue.rawValue }
    }

    var highlightTheme: HighlightTheme {
        get { HighlightTheme(rawValue: highlightThemeRaw) ?? .terracotta }
        set { highlightThemeRaw = newValue.rawValue }
    }
}
