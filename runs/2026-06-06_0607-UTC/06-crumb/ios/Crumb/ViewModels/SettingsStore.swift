import SwiftUI
import Observation

/// Small key/value preferences (permitted in UserDefaults — never the primary store).
/// Every preference here actually changes behavior: units, default dough weight,
/// temperature unit, default scheduling direction, haptics, and appearance.
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

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    /// Mass unit for all weight displays (grams or ounces).
    var massUnit: Units.Mass {
        didSet { defaults.set(massUnit.rawValue, forKey: Keys.massUnit) }
    }
    /// Temperature unit for oven / dough temperatures.
    var temperatureUnit: Units.Temperature {
        didSet { defaults.set(temperatureUnit.rawValue, forKey: Keys.tempUnit) }
    }
    /// Default total dough weight (grams) used when opening a new formula's scaler.
    var defaultDoughGrams: Double {
        didSet { defaults.set(defaultDoughGrams, forKey: Keys.doughGrams) }
    }
    /// When true, new bakes default to scheduling backward from a target finish.
    var schedulesFromFinish: Bool {
        didSet { defaults.set(schedulesFromFinish, forKey: Keys.fromFinish) }
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
        static let massUnit = "settings.massUnit"
        static let tempUnit = "settings.temperatureUnit"
        static let doughGrams = "settings.defaultDoughGrams"
        static let fromFinish = "settings.schedulesFromFinish"
        static let haptics = "settings.haptics"
        static let onboarded = "settings.hasOnboarded"
        static let seeded = "settings.hasSeeded"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        self.massUnit = Units.Mass(rawValue: defaults.string(forKey: Keys.massUnit) ?? "") ?? .grams
        self.temperatureUnit = Units.Temperature(rawValue: defaults.string(forKey: Keys.tempUnit) ?? "") ?? .celsius
        let storedGrams = defaults.double(forKey: Keys.doughGrams)
        self.defaultDoughGrams = storedGrams > 0 ? storedGrams : 900
        self.schedulesFromFinish = defaults.bool(forKey: Keys.fromFinish)
        // Default haptics on; respect a previously stored false.
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        self.hasSeeded = defaults.bool(forKey: Keys.seeded)
    }
}
