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

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "°C"
    case fahrenheit = "°F"

    var id: String { rawValue }
    var label: String { self == .celsius ? "Celsius" : "Fahrenheit" }
}

/// App-wide persisted preferences.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("appearance") var appearanceRaw: String = AppearanceMode.system.rawValue

    // App-specific preferences
    /// Show cycle/period tracking throughout the app (some users are post-menopausal).
    @AppStorage("trackCycle") var trackCycle: Bool = true
    /// Preferred unit for temperature copy (cooling tips, etc.).
    @AppStorage("temperatureUnitRaw") var temperatureUnitRaw: String = TemperatureUnit.fahrenheit.rawValue
    /// Stored as a time-of-day reminder (we persist a Date; only the time component is used in copy).
    @AppStorage("reminderTimeInterval") var reminderTimeInterval: Double = 20 * 3600 // 8:00 PM default
    /// Show the full symptom catalog on Today by default vs. a compact common set.
    @AppStorage("defaultSymptomsShown") var defaultSymptomsShown: Bool = false

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var temperatureUnit: TemperatureUnit {
        get { TemperatureUnit(rawValue: temperatureUnitRaw) ?? .fahrenheit }
        set { temperatureUnitRaw = newValue.rawValue }
    }

    /// The reminder time as a Date today (seconds-of-day applied to the current day).
    var reminderTime: Date {
        get {
            let cal = Calendar.current
            let start = cal.startOfDay(for: Date())
            return start.addingTimeInterval(reminderTimeInterval)
        }
        set {
            let cal = Calendar.current
            let comps = cal.dateComponents([.hour, .minute], from: newValue)
            let seconds = Double((comps.hour ?? 20) * 3600 + (comps.minute ?? 0) * 60)
            reminderTimeInterval = seconds
        }
    }
}
