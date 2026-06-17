import SwiftUI
import Observation

/// Persisted user preferences that actually change behavior.
/// Uses the Observation framework (@Observable) — stored with @State at the app root,
/// shared via the environment. One observation pattern throughout the app.
@Observable
final class AppSettings {
    // Backing UserDefaults keys (small prefs/flags only — primary data is SwiftData).
    private enum Key {
        static let fahrenheit = "useFahrenheit"
        static let pounds = "usePounds"
        static let defaultMethod = "defaultMethodRaw"
        static let stallAlerts = "stallAlertsEnabled"
        static let haptics = "hapticsEnabled"
    }

    var useFahrenheit: Bool {
        didSet { UserDefaults.standard.set(useFahrenheit, forKey: Key.fahrenheit) }
    }
    var usePounds: Bool {
        didSet { UserDefaults.standard.set(usePounds, forKey: Key.pounds) }
    }
    var defaultMethodRaw: String {
        didSet { UserDefaults.standard.set(defaultMethodRaw, forKey: Key.defaultMethod) }
    }
    var stallAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(stallAlertsEnabled, forKey: Key.stallAlerts) }
    }
    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Key.haptics) }
    }

    init() {
        let d = UserDefaults.standard
        // Default to Fahrenheit/pounds (the dominant US BBQ audience), but fully switchable.
        self.useFahrenheit = d.object(forKey: Key.fahrenheit) as? Bool ?? true
        self.usePounds = d.object(forKey: Key.pounds) as? Bool ?? true
        self.defaultMethodRaw = d.string(forKey: Key.defaultMethod) ?? CookMethod.smoke.rawValue
        self.stallAlertsEnabled = d.object(forKey: Key.stallAlerts) as? Bool ?? true
        self.hapticsEnabled = d.object(forKey: Key.haptics) as? Bool ?? true
    }

    var defaultMethod: CookMethod {
        get { CookMethod(rawValue: defaultMethodRaw) ?? .smoke }
        set { defaultMethodRaw = newValue.rawValue }
    }

    // MARK: Display helpers (read the unit prefs)

    func temp(_ celsius: Double) -> String {
        Units.temp(celsius, fahrenheit: useFahrenheit)
    }

    func tempNumeral(_ celsius: Double) -> String {
        Units.tempNumeral(celsius, fahrenheit: useFahrenheit)
    }

    var tempUnitSuffix: String { Units.unitSuffix(fahrenheit: useFahrenheit) }

    func weight(_ kg: Double) -> String {
        Units.weight(kg, pounds: usePounds)
    }

    var weightUnit: String { Units.weightUnit(pounds: usePounds) }
}
