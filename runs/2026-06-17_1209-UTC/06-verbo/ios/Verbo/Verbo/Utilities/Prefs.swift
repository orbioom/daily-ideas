import Foundation

/// Central place for @AppStorage keys + helpers for encoding sets as strings.
enum Prefs {
    static let hasOnboarded = "hasOnboarded"
    static let didSeed = "didSeed"
    static let isPro = "isPro"
    static let answerMode = "answerMode"
    static let accentStrict = "accentStrict"
    static let sessionLength = "sessionLength"
    static let dailyReminder = "dailyReminder"
    static let haptics = "haptics"
    static let frenchEnabled = "frenchEnabled"
    static let enabledTenses = "enabledTenses"   // comma-joined Tense rawValues

    /// Decode a comma-joined string into a set of strings.
    static func decodeSet(_ raw: String) -> Set<String> {
        Set(raw.split(separator: ",").map { String($0) }.filter { !$0.isEmpty })
    }

    /// Encode a set of strings into a comma-joined string (sorted for stability).
    static func encodeSet(_ set: Set<String>) -> String {
        set.sorted().joined(separator: ",")
    }

    /// The default set of enabled tenses (free Spanish core).
    static var defaultEnabledTenses: String {
        encodeSet(Set(Tense.freeSpanishTenses.map { $0.rawValue }))
    }
}
