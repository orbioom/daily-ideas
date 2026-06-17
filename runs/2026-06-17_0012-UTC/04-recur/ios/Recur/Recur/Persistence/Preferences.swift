import Foundation

/// Keys + defaults for @AppStorage-backed preferences. Centralized so the
/// Settings screen and feature screens agree on names and default values.
enum PrefKey {
    static let hasOnboarded = "hasOnboarded"
    static let didSeed = "didSeed"
    static let isPro = "isPro"
    static let hapticsEnabled = "hapticsEnabled"

    static let currencyCode = "currencyCode"
    static let defaultCycle = "defaultCycle"
    static let renewalLeadDays = "renewalLeadDays"
    static let trialLeadDays = "trialLeadDays"
    static let includeTrialsInTotal = "includeTrialsInTotal"
    static let hideAmounts = "hideAmounts"
    static let firstWeekday = "firstWeekday"
    static let notificationsEnabled = "notificationsEnabled"
}

/// Default values applied the first time the app launches.
enum PrefDefault {
    static let currencyCode = "USD"
    static let defaultCycle = "monthly"
    static let renewalLeadDays = 3
    static let trialLeadDays = 3
    static let firstWeekday = 1   // Sunday, matches en_US default
}

/// Free-tier limits (lifted by Recur Pro).
enum FreeTier {
    /// Free users may keep this many active subscriptions before the paywall.
    static let maxSubscriptions = 8
}

/// First-day-of-week options for the calendar grid.
enum WeekStart: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    var id: Int { rawValue }
    var label: String { self == .sunday ? "Sunday" : "Monday" }
}
