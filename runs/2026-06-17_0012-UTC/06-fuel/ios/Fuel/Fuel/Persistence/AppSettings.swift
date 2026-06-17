import SwiftUI
import Observation

/// App-wide preferences. Small flags & display prefs only; all primary data
/// lives in SwiftData. Stored as observable properties (so views re-render on
/// change) and persisted to UserDefaults via `didSet`.
@Observable
final class AppSettings {

    @ObservationIgnored private let defaults: UserDefaults

    enum Keys {
        static let weightUnit = "pref.weightUnit"
        static let heightUnit = "pref.heightUnit"
        static let bmrFormula = "pref.bmrFormula"
        static let proteinPerKg = "pref.proteinPerKg"
        static let refeedCadence = "pref.refeedCadence"
        static let roundTo = "pref.roundTo"
        static let aggressiveness = "pref.aggressiveness"
        static let haptics = "pref.haptics"
    }

    var weightUnit: WeightUnit { didSet { defaults.set(weightUnit.rawValue, forKey: Keys.weightUnit) } }
    var heightUnit: HeightUnit { didSet { defaults.set(heightUnit.rawValue, forKey: Keys.heightUnit) } }
    var bmrFormula: BMRFormula { didSet { defaults.set(bmrFormula.rawValue, forKey: Keys.bmrFormula) } }
    var proteinPerKg: Double { didSet { defaults.set(proteinPerKg, forKey: Keys.proteinPerKg) } }
    var refeedCadence: Int { didSet { defaults.set(max(1, refeedCadence), forKey: Keys.refeedCadence) } }
    var roundTo: Int { didSet { defaults.set(max(1, roundTo), forKey: Keys.roundTo) } }
    var aggressiveness: Aggressiveness { didSet { defaults.set(aggressiveness.rawValue, forKey: Keys.aggressiveness) } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Read existing values, falling back to sensible defaults on first launch.
        weightUnit = WeightUnit(rawValue: defaults.string(forKey: Keys.weightUnit) ?? "") ?? .kg
        heightUnit = HeightUnit(rawValue: defaults.string(forKey: Keys.heightUnit) ?? "") ?? .cm
        bmrFormula = BMRFormula(rawValue: defaults.string(forKey: Keys.bmrFormula) ?? "") ?? .mifflin

        let storedProtein = defaults.double(forKey: Keys.proteinPerKg)
        proteinPerKg = storedProtein > 0 ? storedProtein : 2.0

        let storedCadence = defaults.integer(forKey: Keys.refeedCadence)
        refeedCadence = storedCadence > 0 ? storedCadence : 8

        let storedRound = defaults.integer(forKey: Keys.roundTo)
        roundTo = storedRound > 0 ? storedRound : 10

        aggressiveness = Aggressiveness(rawValue: defaults.string(forKey: Keys.aggressiveness) ?? "") ?? .standard
        hapticsEnabled = defaults.object(forKey: Keys.haptics) == nil ? true : defaults.bool(forKey: Keys.haptics)
    }
}
