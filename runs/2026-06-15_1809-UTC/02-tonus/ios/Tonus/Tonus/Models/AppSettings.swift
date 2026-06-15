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
    /// Play a soft audio cue at each phase change during a session.
    @AppStorage("audioCuesEnabled") var audioCuesEnabled: Bool = true
    /// Daily reminder time (stored as a Date; only the hour/minute are used).
    @AppStorage("reminderTime") var reminderTimeInterval: Double = AppSettings.defaultReminder
    /// Whether the daily reminder is on.
    @AppStorage("reminderEnabled") var reminderEnabled: Bool = false
    /// Target number of finished sessions per week.
    @AppStorage("weeklyGoal") var weeklyGoal: Int = 5
    /// Program shown first on Today / used as the default Start.
    @AppStorage("defaultProgramName") var defaultProgramName: String = "Gentle Start"

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    /// Reminder time as a Date (today at the stored hour/minute).
    var reminderTime: Date {
        get { Date(timeIntervalSinceReferenceDate: reminderTimeInterval) }
        set { reminderTimeInterval = newValue.timeIntervalSinceReferenceDate }
    }

    /// Default: 9:00 AM today, in reference-date interval form.
    static var defaultReminder: Double {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 9
        comps.minute = 0
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.timeIntervalSinceReferenceDate
    }
}
