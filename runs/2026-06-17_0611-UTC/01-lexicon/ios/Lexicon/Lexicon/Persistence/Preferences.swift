import Foundation

/// Keys + defaults for @AppStorage-backed preferences. Centralized so the Settings
/// screen and feature screens agree on names and default values.
enum PrefKey {
    static let hasOnboarded = "hasOnboarded"
    static let isPro = "isPro"
    static let hardMode = "hardMode"
    static let highContrastColors = "highContrastColors"
    static let hapticsEnabled = "hapticsEnabled"
}

/// Free-tier limits, lifted by Lexicon Pro.
enum FreeTier {
    /// Free play covers 4- and 5-letter games. 6-letter is Pro.
    static func isLengthFree(_ length: Int) -> Bool { length != 6 }
    /// How many days back of the daily archive a free user may play.
    static let freeArchiveDays = 7
    /// How many days the full archive spans (for Pro and the list itself).
    static let archiveDays = 60
}
