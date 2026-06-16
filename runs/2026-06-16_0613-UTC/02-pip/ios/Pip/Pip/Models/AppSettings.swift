import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        self == .system ? nil : (self == .light ? .light : .dark)
    }
}

/// Speed of the dice tumble animation. Reduce Motion always forces instant regardless.
enum RollSpeed: String, CaseIterable, Identifiable {
    case off = "Off", fast = "Fast", normal = "Normal", playful = "Playful"
    var id: String { rawValue }

    /// Total duration of the tumble in seconds. `off` is effectively instant.
    var duration: Double {
        switch self {
        case .off: return 0
        case .fast: return 0.35
        case .normal: return 0.6
        case .playful: return 0.95
        }
    }
}

@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("rollSpeed") var rollSpeedRaw = RollSpeed.normal.rawValue
    /// Highlight the suggested dice to hold during a turn (CPU-style hint for humans).
    @AppStorage("autoHoldSuggestions") var autoHoldSuggestions = true
    /// Sort the scorecard by best available preview score instead of canonical order.
    @AppStorage("sortScorecardByValue") var sortScorecardByValue = false

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var rollSpeed: RollSpeed {
        get { RollSpeed(rawValue: rollSpeedRaw) ?? .normal }
        set { rollSpeedRaw = newValue.rawValue }
    }
}
