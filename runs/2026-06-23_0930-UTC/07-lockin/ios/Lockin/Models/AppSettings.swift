import Foundation
import SwiftData

/// Persisted user preferences (a single row).
@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var roundsBeforeLongBreak: Int
    var autoStartBreaks: Bool
    var hapticsEnabled: Bool
    var keepScreenAwake: Bool
    var defaultModeRaw: String

    init(id: UUID = UUID(),
         focusMinutes: Int = 25,
         shortBreakMinutes: Int = 5,
         longBreakMinutes: Int = 15,
         roundsBeforeLongBreak: Int = 4,
         autoStartBreaks: Bool = false,
         hapticsEnabled: Bool = true,
         keepScreenAwake: Bool = true,
         defaultMode: SessionMode = .pomodoro) {
        self.id = id
        self.focusMinutes = focusMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.roundsBeforeLongBreak = roundsBeforeLongBreak
        self.autoStartBreaks = autoStartBreaks
        self.hapticsEnabled = hapticsEnabled
        self.keepScreenAwake = keepScreenAwake
        self.defaultModeRaw = defaultMode.rawValue
    }

    var defaultMode: SessionMode {
        get { SessionMode(rawValue: defaultModeRaw) ?? .pomodoro }
        set { defaultModeRaw = newValue.rawValue }
    }
}
