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
    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// App-wide user preferences. Persisted via @AppStorage so they survive relaunch.
@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue

    /// Weekly target number of applications. Used by the engine for goal progress.
    @AppStorage("weeklyGoal") var weeklyGoal = 5
    /// Default currency for new applications.
    @AppStorage("defaultCurrency") var defaultCurrency = "USD"
    /// How many days after applying with no activity an item is considered "stale".
    @AppStorage("staleAfterDays") var staleAfterDays = 10
    /// Default offset (days) used when enabling a follow-up reminder.
    @AppStorage("followUpDays") var followUpDays = 7

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    static let currencyOptions = ["USD", "EUR", "GBP", "CAD", "AUD", "INR"]
}
