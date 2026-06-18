import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum TempUnit: String, CaseIterable, Identifiable {
    case fahrenheit = "°F", celsius = "°C"
    var id: String { rawValue }
    var short: String { rawValue }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case grams = "g", ounces = "oz"
    var id: String { rawValue }
}

enum TimerSound: String, CaseIterable, Identifiable {
    case classic = "Classic", chime = "Chime", ding = "Ding"
    var id: String { rawValue }
    /// Maps to a bundled-system UNNotificationSound name. We use built-in default for reliability.
    var notificationSoundName: String {
        switch self {
        case .classic: return "default"
        case .chime: return "default"
        case .ding: return "default"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("tempUnit") var tempUnitRaw = TempUnit.fahrenheit.rawValue
    @AppStorage("weightUnit") var weightUnitRaw = WeightUnit.grams.rawValue
    @AppStorage("includePreheat") var includePreheat = false
    @AppStorage("defaultServings") var defaultServings = 1
    @AppStorage("timerSound") var timerSoundRaw = TimerSound.classic.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var tempUnit: TempUnit {
        get { TempUnit(rawValue: tempUnitRaw) ?? .fahrenheit }
        set { tempUnitRaw = newValue.rawValue }
    }

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .grams }
        set { weightUnitRaw = newValue.rawValue }
    }

    var timerSound: TimerSound {
        get { TimerSound(rawValue: timerSoundRaw) ?? .classic }
        set { timerSoundRaw = newValue.rawValue }
    }

    /// Clamped, validated default servings used by the food detail stepper.
    var safeDefaultServings: Int { min(max(defaultServings, 1), 12) }
}
