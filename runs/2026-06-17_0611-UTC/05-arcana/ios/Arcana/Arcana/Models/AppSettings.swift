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

/// Deck-back art themes (a small Pro perk). Affects the back of cards before they're revealed.
enum DeckTheme: String, CaseIterable, Identifiable {
    case midnight = "Midnight"
    case gilded = "Gilded"
    case rose = "Rose Quartz"
    case forest = "Forest"
    var id: String { rawValue }
    var isPro: Bool { self != .midnight }

    var colors: [Color] {
        switch self {
        case .midnight: return [Color(hex: 0x3C2168), Color(hex: 0x120F26)]
        case .gilded: return [Color(hex: 0x6E3AA8), Color(hex: 0xB8881E)]
        case .rose: return [Color(hex: 0x9B5CD8), Color(hex: 0xD46A8C)]
        case .forest: return [Color(hex: 0x2F5E47), Color(hex: 0x120F26)]
        }
    }
}

/// App-wide persisted preferences. All values survive relaunch via `@AppStorage`.
/// Uses ObservableObject + @StateObject (the single ownership pattern used across the app).
@MainActor
final class AppSettings: ObservableObject {
    /// Required: gates all haptic feedback.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Required: allow reversed cards to appear in draws.
    @AppStorage("allowReversals") var allowReversals: Bool = true
    /// Required: a gentle nudge to draw the daily card (local intent flag; no notifications scheduled in demo).
    @AppStorage("dailyCardReminder") var dailyCardReminder: Bool = false
    /// Required: reduce/disable the animated starfield (also auto-overridden by system Reduce Motion).
    @AppStorage("reduceStarfield") var reduceStarfield: Bool = false
    /// System / Light / Dark.
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue
    /// Selected deck-back theme.
    @AppStorage("deckTheme") var deckThemeRaw: String = DeckTheme.midnight.rawValue
    /// Probability (0...1) that a drawn card is reversed, when reversals are allowed.
    @AppStorage("reversalChance") var reversalChance: Double = 0.5

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var deckTheme: DeckTheme {
        get { DeckTheme(rawValue: deckThemeRaw) ?? .midnight }
        set { deckThemeRaw = newValue.rawValue }
    }

    /// The effective reversal probability used by the engine (0 when reversals are off).
    var effectiveReversalChance: Double {
        allowReversals ? min(max(reversalChance, 0), 1) : 0
    }
}
