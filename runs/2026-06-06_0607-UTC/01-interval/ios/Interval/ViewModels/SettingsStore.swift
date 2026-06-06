import SwiftUI
import Observation

/// Small key/value preferences (permitted in UserDefaults — never the primary store).
/// Every preference here actually changes behavior and is applied immediately or on the
/// next run.
@Observable
final class SettingsStore {

    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light:  return .light
            case .dark:   return .dark
            }
        }
    }

    private let defaults: UserDefaults

    /// Lead-in seconds counted down before the first segment (0...10). Drives the
    /// "Prepare" count-in at the start of every run.
    var countInSeconds: Int {
        didSet {
            countInSeconds = min(10, max(0, countInSeconds))
            defaults.set(countInSeconds, forKey: Keys.countIn)
        }
    }

    /// Keep the screen awake during a run (`UIApplication.isIdleTimerDisabled`).
    var keepAwake: Bool {
        didSet { defaults.set(keepAwake, forKey: Keys.keepAwake) }
    }

    /// Master toggle for haptic feedback throughout the app.
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    /// Audible system-sound cues at transitions / count-in / completion.
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// First-run gate. Persisted so onboarding shows exactly once.
    var hasLaunchedBefore: Bool {
        didSet { defaults.set(hasLaunchedBefore, forKey: Keys.launched) }
    }

    /// Whether the sample routines have been seeded into the store.
    var hasSeeded: Bool {
        didSet { defaults.set(hasSeeded, forKey: Keys.seeded) }
    }

    private enum Keys {
        static let countIn = "settings.countInSeconds"
        static let keepAwake = "settings.keepAwake"
        static let haptics = "settings.haptics"
        static let sound = "settings.sound"
        static let appearance = "settings.appearance"
        static let launched = "settings.hasLaunchedBefore"
        static let seeded = "settings.hasSeeded"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.countInSeconds = defaults.object(forKey: Keys.countIn) as? Int ?? 3
        self.keepAwake = defaults.object(forKey: Keys.keepAwake) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        self.hasLaunchedBefore = defaults.bool(forKey: Keys.launched)
        self.hasSeeded = defaults.bool(forKey: Keys.seeded)
        // Clamp count-in defensively in case of an out-of-range stored value.
        self.countInSeconds = min(10, max(0, self.countInSeconds))
    }

    /// Used by the "reset sample data" path so the seeder runs again.
    func clearSeedFlag() { hasSeeded = false }
}
