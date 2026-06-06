import SwiftUI
import Observation

/// Small key/value preferences (permitted in UserDefaults — never the primary store).
/// Every preference here actually changes behavior and is applied on next use/launch.
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

    /// Default increment the calculator snaps to and enumerates equivalents in.
    var defaultIncrement: StopIncrement {
        didSet { defaults.set(defaultIncrement.rawValue, forKey: Keys.increment) }
    }
    /// Default film stock prefilled when creating a new roll.
    var defaultFilmStock: String {
        didSet { defaults.set(defaultFilmStock, forKey: Keys.filmStock) }
    }
    /// Default ISO prefilled when creating a new roll.
    var defaultISO: Double {
        didSet { defaults.set(defaultISO, forKey: Keys.iso) }
    }
    /// Units for focal-length / distance presentation.
    var units: UnitSystem {
        didSet { defaults.set(units.rawValue, forKey: Keys.units) }
    }
    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
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
        static let increment = "settings.defaultIncrement"
        static let filmStock = "settings.defaultFilmStock"
        static let iso = "settings.defaultISO"
        static let units = "settings.units"
        static let appearance = "settings.appearance"
        static let haptics = "settings.haptics"
        static let onboarded = "settings.hasOnboarded"
        static let seeded = "settings.hasSeeded"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.defaultIncrement = StopIncrement(rawValue: defaults.string(forKey: Keys.increment) ?? "") ?? .third
        self.defaultFilmStock = defaults.string(forKey: Keys.filmStock) ?? "Kodak Portra 400"
        let storedISO = defaults.double(forKey: Keys.iso)
        self.defaultISO = storedISO > 0 ? storedISO : 400
        self.units = UnitSystem(rawValue: defaults.string(forKey: Keys.units) ?? "") ?? .metric
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        self.hasSeeded = defaults.bool(forKey: Keys.seeded)
    }
}
