import Foundation

/// Central registry of @AppStorage keys so they're spelled the same everywhere.
enum PrefKey {
    static let hasOnboarded = "hasOnboarded"
    static let isPro = "isPro"

    static let emergencyContactName = "emergencyContactName"
    static let emergencyContactPhone = "emergencyContactPhone"

    static let defaultBreathingPattern = "defaultBreathingPattern"
    static let hapticsEnabled = "hapticsEnabled"
    static let reduceVisualsExtra = "reduceVisualsExtra"
    static let showCrisisLine = "showCrisisLine"
    static let gentleReminders = "gentleReminders"

    // Safety plan
    static let safetyWarningSigns = "safetyWarningSigns"
    static let safetyReasons = "safetyReasons"
    static let safetyWhoToCall = "safetyWhoToCall"
}

/// Free-tier limits. Custom items beyond these caps require Haven Plus.
enum Limits {
    static let freeCustomCopingCap = 2
    static let freeCustomReassuranceCap = 2
    static let freeCustomTriggerCap = 2
}

/// Crisis resource shown calmly throughout the app.
enum CrisisInfo {
    static let lineLabel = "988 Suicide & Crisis Lifeline (US)"
    static let dial = "988"
    static let smsBody = "If you're in crisis, you can call or text 988 (US). In an emergency, call your local emergency number."
}

/// Small helpers for building safe `tel:` URLs.
enum PhoneURL {
    /// Returns a sanitised `tel:` URL if the string contains usable digits.
    static func make(from raw: String) -> URL? {
        let allowed = CharacterSet(charactersIn: "0123456789+")
        let trimmed = raw.unicodeScalars.filter { allowed.contains($0) }
        let digits = String(String.UnicodeScalarView(trimmed))
        guard digits.count >= 3 else { return nil }
        return URL(string: "tel:\(digits)")
    }
}
