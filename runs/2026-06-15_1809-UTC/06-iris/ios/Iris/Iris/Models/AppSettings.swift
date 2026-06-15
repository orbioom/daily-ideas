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

    /// 20-20-20 interval in minutes (how long between recommended eye breaks).
    @AppStorage("breakIntervalMinutes") var breakIntervalMinutes: Int = 20
    /// How many eye breaks the user is aiming for each day.
    @AppStorage("dailyBreakGoal") var dailyBreakGoal: Int = 8
    /// Whether the Today screen nudges when a break is due.
    @AppStorage("breakReminderEnabled") var breakReminderEnabled: Bool = true
    /// Whether the Today screen surfaces a recommended exercise routine.
    @AppStorage("exerciseReminderEnabled") var exerciseReminderEnabled: Bool = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    /// Clamped, safe interval in seconds for the scheduler. Never zero/negative.
    var breakIntervalSeconds: Double {
        Double(max(1, breakIntervalMinutes)) * 60.0
    }

    /// Clamped, safe daily goal. Never zero/negative (used as a divisor).
    var safeDailyGoal: Int {
        max(1, dailyBreakGoal)
    }
}
