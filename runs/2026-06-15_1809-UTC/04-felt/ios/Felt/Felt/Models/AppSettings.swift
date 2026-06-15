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

/// App-wide persisted preferences.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue

    /// Default game type pre-selected when adding a new session.
    @AppStorage("defaultGameType") var defaultGameTypeRaw: String = GameType.nlhe.rawValue
    /// Currency symbol used for all money figures.
    @AppStorage("currencySymbol") var currencySymbol: String = "$"
    /// On the dashboard hero, lead with hourly rate instead of total profit.
    @AppStorage("hourlyInsteadOfTotal") var hourlyInsteadOfTotal: Bool = false
    /// Privacy: blur all money amounts until revealed.
    @AppStorage("hideAmounts") var hideAmounts: Bool = false

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultGameType: GameType {
        get { GameType(rawValue: defaultGameTypeRaw) ?? .nlhe }
        set { defaultGameTypeRaw = newValue.rawValue }
    }
}
