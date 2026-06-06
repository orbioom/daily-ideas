import SwiftUI
import Observation

/// Small key/value preferences (permitted in UserDefaults — never the primary store).
/// Every preference here actually changes behavior and survives relaunch.
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

    /// Bounds for the default-session-length preference, in minutes.
    static let minSessionMinutes = 5
    static let maxSessionMinutes = 120

    /// Bounds for the A4 concert-pitch reference, in Hz.
    static let minReferenceHz = 415
    static let maxReferenceHz = 466

    private let defaults: UserDefaults

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// Minutes the countdown practice timer starts at when you open a new session.
    var defaultSessionMinutes: Int {
        didSet {
            let clamped = min(Self.maxSessionMinutes, max(Self.minSessionMinutes, defaultSessionMinutes))
            if clamped != defaultSessionMinutes { defaultSessionMinutes = clamped; return }
            defaults.set(defaultSessionMinutes, forKey: Keys.sessionMinutes)
        }
    }

    /// Concert-pitch A4 reference in Hz, surfaced on the practice screen and tuner readout.
    var referenceHz: Int {
        didSet {
            let clamped = min(Self.maxReferenceHz, max(Self.minReferenceHz, referenceHz))
            if clamped != referenceHz { referenceHz = clamped; return }
            defaults.set(referenceHz, forKey: Keys.referenceHz)
        }
    }

    /// Whether the metronome produces a soft system tick alongside the visual pulse.
    var metronomeSoundEnabled: Bool {
        didSet { defaults.set(metronomeSoundEnabled, forKey: Keys.metronomeSound) }
    }

    /// Default metronome BPM offered when starting a fresh session.
    var defaultBPM: Int {
        didSet {
            let clamped = Tempo.clamp(defaultBPM)
            if clamped != defaultBPM { defaultBPM = clamped; return }
            defaults.set(defaultBPM, forKey: Keys.defaultBPM)
        }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    var hasOnboarded: Bool {
        didSet { defaults.set(hasOnboarded, forKey: Keys.onboarded) }
    }

    var hasSeeded: Bool {
        didSet { defaults.set(hasSeeded, forKey: Keys.seeded) }
    }

    private enum Keys {
        static let appearance = "settings.appearance"
        static let sessionMinutes = "settings.defaultSessionMinutes"
        static let referenceHz = "settings.referenceHz"
        static let metronomeSound = "settings.metronomeSound"
        static let defaultBPM = "settings.defaultBPM"
        static let haptics = "settings.haptics"
        static let onboarded = "settings.hasOnboarded"
        static let seeded = "settings.hasSeeded"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        let storedSession = defaults.object(forKey: Keys.sessionMinutes) as? Int ?? 25
        self.defaultSessionMinutes = min(Self.maxSessionMinutes, max(Self.minSessionMinutes, storedSession))
        let storedHz = defaults.object(forKey: Keys.referenceHz) as? Int ?? 440
        self.referenceHz = min(Self.maxReferenceHz, max(Self.minReferenceHz, storedHz))
        self.metronomeSoundEnabled = defaults.object(forKey: Keys.metronomeSound) as? Bool ?? true
        let storedBPM = defaults.object(forKey: Keys.defaultBPM) as? Int ?? 80
        self.defaultBPM = Tempo.clamp(storedBPM)
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        self.hasSeeded = defaults.bool(forKey: Keys.seeded)
    }
}
