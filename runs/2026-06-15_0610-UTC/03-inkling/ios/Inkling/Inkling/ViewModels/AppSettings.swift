import SwiftUI

/// The default time window used by Insights and Trends, persisted across launches.
enum TimeRange: String, CaseIterable, Identifiable, Codable {
    case days30
    case days90
    case all

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .days30: return 30
        case .days90: return 90
        case .all: return nil
        }
    }

    var label: String {
        switch self {
        case .days30: return "30 days"
        case .days90: return "90 days"
        case .all: return "All time"
        }
    }

    var shortLabel: String {
        switch self {
        case .days30: return "30d"
        case .days90: return "90d"
        case .all: return "All"
        }
    }
}

/// Persisted user preferences that genuinely change behaviour across the app.
@MainActor
final class AppSettings: ObservableObject {
    /// Severity scale: false = 0–4 (default), true = 0–10. Affects logging sliders and display.
    @AppStorage("useScale10") var useScale10: Bool = false
    /// Default time range for Insights and Trends.
    @AppStorage("defaultRangeRaw") var defaultRangeRaw: String = TimeRange.days30.rawValue
    /// Sparse haptics, gated everywhere they fire.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Daily reminder toggle + time (minutes from midnight). Drives a local notification.
    @AppStorage("reminderEnabled") var reminderEnabled: Bool = false
    @AppStorage("reminderMinutes") var reminderMinutes: Int = 20 * 60   // 8:00 pm default
    /// Appearance: system / light / dark.
    @AppStorage("appearanceRaw") var appearanceRaw: String = Appearance.system.rawValue

    var defaultRange: TimeRange {
        get { TimeRange(rawValue: defaultRangeRaw) ?? .days30 }
        set { defaultRangeRaw = newValue.rawValue }
    }

    var appearance: Appearance {
        get { Appearance(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}

/// App appearance override (a real, persisted preference).
enum Appearance: String, CaseIterable, Identifiable, Codable {
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

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.stars"
        }
    }
}
