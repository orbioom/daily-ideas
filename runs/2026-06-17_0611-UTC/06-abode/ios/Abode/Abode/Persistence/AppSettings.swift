import SwiftUI
import Observation

/// App-wide display preferences & calculator defaults. Small flags only — all primary
/// data lives in SwiftData. Observable so views re-render, persisted via `didSet`.
@Observable
final class AppSettings {

    @ObservationIgnored private let defaults: UserDefaults

    enum Keys {
        static let currencyCode = "pref.currencyCode"
        static let defaultRatePct = "pref.defaultRatePct"
        static let defaultTermYears = "pref.defaultTermYears"
        static let defaultPropertyTaxPct = "pref.defaultPropertyTaxPct"
        static let showCents = "pref.showCents"
        static let haptics = "pref.haptics"
    }

    var currencyCode: String { didSet { defaults.set(currencyCode, forKey: Keys.currencyCode); syncFormat() } }
    var defaultRatePct: Double { didSet { defaults.set(defaultRatePct, forKey: Keys.defaultRatePct) } }
    var defaultTermYears: Int { didSet { defaults.set(max(1, defaultTermYears), forKey: Keys.defaultTermYears) } }
    var defaultPropertyTaxPct: Double { didSet { defaults.set(defaultPropertyTaxPct, forKey: Keys.defaultPropertyTaxPct) } }
    var showCents: Bool { didSet { defaults.set(showCents, forKey: Keys.showCents); syncFormat() } }
    var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        currencyCode = defaults.string(forKey: Keys.currencyCode) ?? "USD"

        let storedRate = defaults.double(forKey: Keys.defaultRatePct)
        defaultRatePct = storedRate > 0 ? storedRate : 6.5

        let storedTerm = defaults.integer(forKey: Keys.defaultTermYears)
        defaultTermYears = storedTerm > 0 ? storedTerm : 30

        let storedTax = defaults.double(forKey: Keys.defaultPropertyTaxPct)
        defaultPropertyTaxPct = storedTax > 0 ? storedTax : 1.1

        showCents = defaults.object(forKey: Keys.showCents) == nil ? false : defaults.bool(forKey: Keys.showCents)
        hapticsEnabled = defaults.object(forKey: Keys.haptics) == nil ? true : defaults.bool(forKey: Keys.haptics)

        syncFormat()
    }

    /// Pushes display prefs into the shared Format helper.
    private func syncFormat() {
        Format.configure(currencyCode: currencyCode, showCents: showCents)
    }

    /// Supported display currencies for the Settings picker.
    static let supportedCurrencies: [(code: String, label: String)] = [
        ("USD", "US Dollar ($)"),
        ("EUR", "Euro (€)"),
        ("GBP", "British Pound (£)"),
        ("CAD", "Canadian Dollar (C$)"),
        ("AUD", "Australian Dollar (A$)"),
        ("INR", "Indian Rupee (₹)")
    ]
}
