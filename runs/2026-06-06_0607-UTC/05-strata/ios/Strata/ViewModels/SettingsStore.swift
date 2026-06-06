import SwiftUI
import Observation

/// Small key/value preferences (permitted in UserDefaults — never the primary store).
/// Every preference here actually changes behavior and is applied on display.
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
    /// Preferred display system for boulder grades (V-scale or Font).
    var boulderSystem: GradeSystem {
        didSet { defaults.set(boulderSystem.rawValue, forKey: Keys.boulderSystem) }
    }
    /// Preferred display system for route grades (YDS or French).
    var routeSystem: GradeSystem {
        didSet { defaults.set(routeSystem.rawValue, forKey: Keys.routeSystem) }
    }
    /// Default discipline used when composing a new climb.
    var defaultDiscipline: Discipline {
        didSet { defaults.set(defaultDiscipline.rawValue, forKey: Keys.discipline) }
    }
    /// Default location id (as a UUID string) preselected for new sessions/climbs.
    var defaultLocationID: String {
        didSet { defaults.set(defaultLocationID, forKey: Keys.location) }
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
        static let boulderSystem = "settings.boulderSystem"
        static let routeSystem = "settings.routeSystem"
        static let discipline = "settings.defaultDiscipline"
        static let location = "settings.defaultLocation"
        static let haptics = "settings.haptics"
        static let onboarded = "settings.hasOnboarded"
        static let seeded = "settings.hasSeeded"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        // Guard system/family alignment: a boulder system for the boulder slot, route for route.
        let storedBoulder = GradeSystem(rawValue: defaults.string(forKey: Keys.boulderSystem) ?? "")
        self.boulderSystem = (storedBoulder?.family == .boulder ? storedBoulder : nil) ?? .vScale
        let storedRoute = GradeSystem(rawValue: defaults.string(forKey: Keys.routeSystem) ?? "")
        self.routeSystem = (storedRoute?.family == .route ? storedRoute : nil) ?? .yds
        self.defaultDiscipline = Discipline(rawValue: defaults.string(forKey: Keys.discipline) ?? "") ?? .boulder
        self.defaultLocationID = defaults.string(forKey: Keys.location) ?? ""
        // Default haptics on; respect a previously stored false.
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.hasOnboarded = defaults.bool(forKey: Keys.onboarded)
        self.hasSeeded = defaults.bool(forKey: Keys.seeded)
    }

    /// Resolve the preferred display system for a grade family.
    func system(for family: GradeFamily) -> GradeSystem {
        family == .boulder ? boulderSystem : routeSystem
    }
}
