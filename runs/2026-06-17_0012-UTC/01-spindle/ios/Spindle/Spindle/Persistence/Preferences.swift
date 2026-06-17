import Foundation

/// Keys + defaults for @AppStorage-backed preferences. Centralized so the
/// Settings screen and feature screens agree on names and default values.
enum PrefKey {
    static let hasOnboarded = "hasOnboarded"
    static let isPro = "isPro"
    static let hapticsEnabled = "hapticsEnabled"
    static let leftHandedToolbar = "leftHandedToolbar"
    static let feltTheme = "feltTheme"
    static let cardBackStyle = "cardBackStyle"
    static let showTimer = "showTimer"
    static let animationsEnabled = "animationsEnabled"
    static let autoFlip = "autoFlip"
    static let confirmNewGame = "confirmNewGame"
    static let lastSuitMode = "lastSuitMode"
}

/// Free-tier limits, lifted by Spindle Pro.
enum FreeTier {
    /// Free play covers 1- and 2-suit. 4-suit is Pro.
    static func isModeFree(_ mode: SuitMode) -> Bool { !mode.requiresPro }
    /// Free felt themes (just Emerald). Extras are Pro.
    static func isFeltFree(_ felt: FeltTheme) -> Bool { !felt.requiresPro }
    /// How many days of daily-deal archive a free user may browse back.
    static let freeDailyArchiveDays = 1
    static let proDailyArchiveDays = 30
}
