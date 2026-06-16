import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}

/// Whether the sky is computed for "now" or for a custom moment (Pro time-travel).
enum TimeMode: String, CaseIterable, Identifiable {
    case now = "Now", custom = "Custom"
    var id: String { rawValue }
}

@MainActor final class AppSettings: ObservableObject {
    // Appearance
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue

    // Haptics
    @AppStorage("hapticsEnabled") var hapticsEnabled = true

    // Chart preferences
    @AppStorage("showConstellationLines") var showConstellationLines = true
    @AppStorage("showLabels") var showLabels = true

    /// Faintest magnitude plotted on the chart (higher = more, fainter stars).
    @AppStorage("magnitudeLimit") var magnitudeLimit: Double = 4.5

    // Location selection — id into the SavedLocation / gazetteer.
    @AppStorage("selectedLocationID") var selectedLocationID = "city.london"

    // Manual coordinate override (used when selectedLocationID == manual marker).
    @AppStorage("manualLatitude") var manualLatitude: Double = 51.5074
    @AppStorage("manualLongitude") var manualLongitude: Double = -0.1278
    @AppStorage("manualLocationName") var manualLocationName = "Custom location"

    // Time mode + a time-travel offset stored as an absolute reference date.
    @AppStorage("timeMode") var timeModeRaw = TimeMode.now.rawValue
    /// Custom moment as seconds since reference date (used when timeMode == custom).
    @AppStorage("customDate") var customDateInterval: Double = Date().timeIntervalSinceReferenceDate

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var timeMode: TimeMode {
        get { TimeMode(rawValue: timeModeRaw) ?? .now }
        set { timeModeRaw = newValue.rawValue }
    }

    var customDate: Date {
        get { Date(timeIntervalSinceReferenceDate: customDateInterval) }
        set { customDateInterval = newValue.timeIntervalSinceReferenceDate }
    }
}
