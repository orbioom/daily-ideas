import SwiftUI
import Observation

/// Small key/value preferences (permitted in UserDefaults — never the primary store).
/// Every preference here actually changes behavior and is applied on next launch.
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

    enum SortOrder: String, CaseIterable, Identifiable {
        case recentlyAdded, recentlyTasted, name, rating
        var id: String { rawValue }
        var title: String {
            switch self {
            case .recentlyAdded:  return "Recently added"
            case .recentlyTasted: return "Recently tasted"
            case .name:           return "Name"
            case .rating:         return "Highest rated"
            }
        }
    }

    private let defaults: UserDefaults

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    var defaultSort: SortOrder {
        didSet { defaults.set(defaultSort.rawValue, forKey: Keys.sort) }
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
        static let sort = "settings.defaultSort"
        static let haptics = "settings.haptics"
        static let onboarded = "settings.hasOnboarded"
        static let seeded = "settings.hasSeeded"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        self.defaultSort = SortOrder(rawValue: defaults.string(forKey: Keys.sort) ?? "") ?? .recentlyAdded
        // Default haptics on; respect a previously stored false.
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        self.hasSeeded = defaults.bool(forKey: Keys.seeded)
    }
}
