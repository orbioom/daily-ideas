import SwiftUI
import Observation

/// App-wide preferences. Small flags & display prefs only; all primary data
/// lives in SwiftData. Observable so views re-render, persisted to UserDefaults
/// via `didSet`.
@Observable
final class AppSettings {

    @ObservationIgnored private let defaults: UserDefaults

    enum Keys {
        static let defaultTimerMinutes = "pref.defaultTimerMinutes"
        static let fadeOutSeconds = "pref.fadeOutSeconds"
        static let haptics = "pref.haptics"
        static let maxLayers = "pref.maxLayers"
    }

    /// Default duration (minutes) pre-selected on the Timer screen.
    var defaultTimerMinutes: Int { didSet { defaults.set(max(1, defaultTimerMinutes), forKey: Keys.defaultTimerMinutes) } }
    /// How long the master volume tapers to silence at the end of a timer.
    var fadeOutSeconds: Double { didSet { defaults.set(max(0, fadeOutSeconds), forKey: Keys.fadeOutSeconds) } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) } }
    /// The free-tier cap on simultaneous layers (info/display; not user-editable).
    var maxLayers: Int { didSet { defaults.set(max(1, maxLayers), forKey: Keys.maxLayers) } }

    /// The free-tier layer cap constant.
    static let freeLayerCap = 3

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedTimer = defaults.integer(forKey: Keys.defaultTimerMinutes)
        defaultTimerMinutes = storedTimer > 0 ? storedTimer : 45

        let storedFade = defaults.object(forKey: Keys.fadeOutSeconds) as? Double
        fadeOutSeconds = storedFade ?? 30

        hapticsEnabled = defaults.object(forKey: Keys.haptics) == nil ? true : defaults.bool(forKey: Keys.haptics)

        let storedMax = defaults.integer(forKey: Keys.maxLayers)
        maxLayers = storedMax > 0 ? storedMax : AppSettings.freeLayerCap
    }
}
