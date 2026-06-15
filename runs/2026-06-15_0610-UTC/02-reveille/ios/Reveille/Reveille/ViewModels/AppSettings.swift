import SwiftUI

/// Persisted preferences that actually change behavior across the app. Small flags only —
/// the alarm/log data lives in SwiftData.
@MainActor
final class AppSettings: ObservableObject {
    /// Sparse haptics on selection / mission step / completion / warnings.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Use a 24-hour clock everywhere times are shown.
    @AppStorage("use24Hour") var use24Hour: Bool = false
    /// Vibrate the phone repeatedly while an alarm is ringing.
    @AppStorage("vibrateOnRing") var vibrateOnRing: Bool = true
    /// Keep the screen awake on the Ring and Bedside screens.
    @AppStorage("keepScreenOn") var keepScreenOn: Bool = true
    /// Default snooze length (minutes) prefilled when creating a new alarm.
    @AppStorage("defaultSnoozeMinutes") var defaultSnoozeMinutes: Int = 9
    /// Default sound prefilled when creating a new alarm.
    @AppStorage("defaultSoundName") var defaultSoundName: String = SoundLibrary.defaultSoundName
    /// Bedside clock theme id (Pro themes fall back to dawn when locked).
    @AppStorage("bedsideTheme") var bedsideThemeID: String = BedsideTheme.dawn.id

    /// Resolve the active bedside theme, honoring Pro gating.
    func bedsideTheme(isPro: Bool) -> BedsideTheme {
        let theme = BedsideTheme.theme(id: bedsideThemeID)
        if theme.isPro && !isPro { return .dawn }
        return theme
    }

    /// Clamp the default snooze into a sane range when read.
    var safeDefaultSnooze: Int { min(30, max(1, defaultSnoozeMinutes)) }
}
