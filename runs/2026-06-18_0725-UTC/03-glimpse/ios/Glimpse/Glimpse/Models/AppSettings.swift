import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        self == .system ? nil : (self == .light ? .light : .dark)
    }
}

/// Density of the calendar / montage thumbnail grids.
enum GridDensity: String, CaseIterable, Identifiable {
    case cozy = "Cozy", standard = "Standard", compact = "Compact"
    var id: String { rawValue }
    var columns: Int {
        switch self {
        case .cozy: return 3
        case .standard: return 4
        case .compact: return 5
        }
    }
}

/// First day of the week for the calendar grid.
enum WeekStart: String, CaseIterable, Identifiable {
    case sunday = "Sunday", monday = "Monday"
    var id: String { rawValue }
    /// Calendar weekday index (1 = Sunday … 7 = Saturday).
    var weekdayIndex: Int { self == .sunday ? 1 : 2 }
}

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("defaultMood") var defaultMoodRaw = Mood.good.rawValue
    @AppStorage("weekStart") var weekStartRaw = WeekStart.monday.rawValue
    @AppStorage("gridDensity") var gridDensityRaw = GridDensity.standard.rawValue
    @AppStorage("reminderEnabled") var reminderEnabled = false
    /// Stored as minutes-since-midnight so it survives in @AppStorage cleanly.
    @AppStorage("reminderMinutes") var reminderMinutes = 20 * 60 // 20:00

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultMood: Mood {
        get { Mood.from(defaultMoodRaw) }
        set { defaultMoodRaw = newValue.rawValue }
    }

    var weekStart: WeekStart {
        get { WeekStart(rawValue: weekStartRaw) ?? .monday }
        set { weekStartRaw = newValue.rawValue }
    }

    var gridDensity: GridDensity {
        get { GridDensity(rawValue: gridDensityRaw) ?? .standard }
        set { gridDensityRaw = newValue.rawValue }
    }

    /// Reminder time as hour/minute components (clamped to a valid range).
    var reminderTime: DateComponents {
        get {
            let clamped = min(max(reminderMinutes, 0), 23 * 60 + 59)
            return DateComponents(hour: clamped / 60, minute: clamped % 60)
        }
        set {
            let h = newValue.hour ?? 20
            let m = newValue.minute ?? 0
            reminderMinutes = min(max(h, 0), 23) * 60 + min(max(m, 0), 59)
        }
    }
}
