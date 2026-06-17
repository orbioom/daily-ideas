import SwiftUI
import Observation

/// App-wide preferences. Small flags & display prefs only; all primary data
/// lives in SwiftData. Observable so views re-render on change; mirrored to
/// UserDefaults via `didSet`.
@Observable
final class AppSettings {

    @ObservationIgnored private let defaults: UserDefaults

    enum Keys {
        static let voiceCues = "pref.voiceCues"
        static let countdownBeeps = "pref.countdownBeeps"
        static let hapticCues = "pref.hapticCues"
        static let keepAwake = "pref.keepAwake"
        static let units = "pref.units"
        static let remindersEnabled = "pref.remindersEnabled"
    }

    var voiceCuesEnabled: Bool { didSet { defaults.set(voiceCuesEnabled, forKey: Keys.voiceCues) } }
    var countdownBeeps: Bool { didSet { defaults.set(countdownBeeps, forKey: Keys.countdownBeeps) } }
    var hapticCues: Bool { didSet { defaults.set(hapticCues, forKey: Keys.hapticCues) } }
    var keepAwake: Bool { didSet { defaults.set(keepAwake, forKey: Keys.keepAwake) } }
    var units: DistanceUnit { didSet { defaults.set(units.rawValue, forKey: Keys.units) } }
    var remindersEnabled: Bool { didSet { defaults.set(remindersEnabled, forKey: Keys.remindersEnabled) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        func boolOrTrue(_ key: String) -> Bool {
            defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key)
        }

        voiceCuesEnabled = boolOrTrue(Keys.voiceCues)
        countdownBeeps = boolOrTrue(Keys.countdownBeeps)
        hapticCues = boolOrTrue(Keys.hapticCues)
        keepAwake = boolOrTrue(Keys.keepAwake)
        units = DistanceUnit(rawValue: defaults.string(forKey: Keys.units) ?? "") ?? .km
        // Reminders default OFF (no notification permission requested unasked).
        remindersEnabled = defaults.bool(forKey: Keys.remindersEnabled)
    }
}
