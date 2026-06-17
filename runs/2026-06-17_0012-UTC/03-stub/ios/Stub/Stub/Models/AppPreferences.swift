import SwiftUI

/// Small, persisted user preferences backed by @AppStorage.
/// Defaults seed the Calculator on first load; toggles affect formatting & UX.
@Observable
final class AppPreferences {

    // Backing UserDefaults keys.
    private enum Key {
        static let defaultFiling = "pref_defaultFiling"
        static let defaultState = "pref_defaultState"
        static let defaultFrequency = "pref_defaultFrequency"
        static let showAnnualDefault = "pref_showAnnualDefault"
        static let roundWhole = "pref_roundWhole"
        static let haptics = "pref_haptics"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Register sensible defaults once.
        defaults.register(defaults: [
            Key.defaultFiling: FilingStatus.single.rawValue,
            Key.defaultState: "CA",
            Key.defaultFrequency: PayFrequency.biweekly.rawValue,
            Key.showAnnualDefault: false,
            Key.roundWhole: false,
            Key.haptics: true
        ])
    }

    var defaultFiling: FilingStatus {
        get { FilingStatus(rawValue: defaults.string(forKey: Key.defaultFiling) ?? "") ?? .single }
        set { defaults.set(newValue.rawValue, forKey: Key.defaultFiling) }
    }

    var defaultStateCode: String {
        get { defaults.string(forKey: Key.defaultState) ?? "CA" }
        set { defaults.set(newValue, forKey: Key.defaultState) }
    }

    var defaultFrequency: PayFrequency {
        get { PayFrequency(rawValue: defaults.string(forKey: Key.defaultFrequency) ?? "") ?? .biweekly }
        set { defaults.set(newValue.rawValue, forKey: Key.defaultFrequency) }
    }

    /// Whether Breakdown / hero default to annual figures (vs per-paycheck).
    var showAnnualByDefault: Bool {
        get { defaults.bool(forKey: Key.showAnnualDefault) }
        set { defaults.set(newValue, forKey: Key.showAnnualDefault) }
    }

    /// Round all currency to whole dollars.
    var roundWhole: Bool {
        get { defaults.bool(forKey: Key.roundWhole) }
        set { defaults.set(newValue, forKey: Key.roundWhole) }
    }

    /// Enable subtle haptic feedback.
    var hapticsEnabled: Bool {
        get { defaults.bool(forKey: Key.haptics) }
        set { defaults.set(newValue, forKey: Key.haptics) }
    }
}
