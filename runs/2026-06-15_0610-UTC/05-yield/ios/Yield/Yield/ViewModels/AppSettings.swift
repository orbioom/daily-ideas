import SwiftUI

/// Persisted user preferences that actually change behavior across the app.
/// Stored in UserDefaults via @AppStorage (small prefs only; holdings live in SwiftData).
@MainActor
final class AppSettings: ObservableObject {
    /// ISO currency code used by all money formatting.
    @AppStorage("currencyCode") var currencyCode: String = "USD"
    /// Annual dividend-income goal (whole units of the chosen currency). Drives the goal ring.
    @AppStorage("annualGoal") var annualGoal: Double = 6000
    /// Default annual dividend-growth rate used to seed the DRIP projector (e.g. 0.06).
    @AppStorage("defaultGrowthRate") var defaultGrowthRate: Double = 0.06
    /// Privacy: blur/replace money figures with dots (Pro feature; falls back off if not Pro).
    @AppStorage("hideBalances") var hideBalancesPref: Bool = false
    /// Sparse haptics toggle.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Appearance: system / light / dark.
    @AppStorage("appearance") var appearanceRaw: String = Appearance.system.rawValue

    var appearance: Appearance {
        get { Appearance(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    /// The effective color scheme override for the whole app, or nil to follow system.
    var preferredColorScheme: ColorScheme? { appearance.colorScheme }

    /// Hide-balances only applies when Pro is unlocked.
    func balancesHidden(isPro: Bool) -> Bool { isPro && hideBalancesPref }

    /// Common currency choices offered in Settings.
    static let currencyChoices: [String] = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CHF", "INR"]
}

/// App appearance preference.
enum Appearance: String, CaseIterable, Identifiable {
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
