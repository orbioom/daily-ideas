import SwiftUI
import Observation

/// Shared, persisted user preferences. Backed by `UserDefaults` so values survive relaunch.
/// Created once in the App and injected via the environment.
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var currencyCode: String {
        didSet { defaults.set(currencyCode, forKey: Keys.currencyCode) }
    }
    /// 1...28; the day each savings "month" rolls over for reminders/pacing display.
    var firstDayOfMonth: Int {
        didSet { defaults.set(firstDayOfMonth, forKey: Keys.firstDayOfMonth) }
    }
    var defaultStrategyRaw: String {
        didSet { defaults.set(defaultStrategyRaw, forKey: Keys.defaultStrategy) }
    }
    var hideAmounts: Bool {
        didSet { defaults.set(hideAmounts, forKey: Keys.hideAmounts) }
    }
    var monthlyReminder: Bool {
        didSet { defaults.set(monthlyReminder, forKey: Keys.monthlyReminder) }
    }
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.currencyCode: "USD",
            Keys.firstDayOfMonth: 1,
            Keys.defaultStrategy: AllocationStrategy.proportionalToNeed.rawValue,
            Keys.hideAmounts: false,
            Keys.monthlyReminder: false,
            Keys.haptics: true
        ])
        self.currencyCode = defaults.string(forKey: Keys.currencyCode) ?? "USD"
        self.firstDayOfMonth = defaults.integer(forKey: Keys.firstDayOfMonth)
        self.defaultStrategyRaw = defaults.string(forKey: Keys.defaultStrategy)
            ?? AllocationStrategy.proportionalToNeed.rawValue
        self.hideAmounts = defaults.bool(forKey: Keys.hideAmounts)
        self.monthlyReminder = defaults.bool(forKey: Keys.monthlyReminder)
        self.hapticsEnabled = defaults.bool(forKey: Keys.haptics)
    }

    var currency: CurrencyOption { CurrencyOption.option(forCode: currencyCode) }

    var defaultStrategy: AllocationStrategy {
        get { AllocationStrategy(rawValue: defaultStrategyRaw) ?? .proportionalToNeed }
        set { defaultStrategyRaw = newValue.rawValue }
    }

    /// Format an amount, honoring the privacy "hide amounts" toggle.
    func display(_ value: Double, fractionDigits: Int = 2) -> String {
        guard !hideAmounts else { return "•••••" }
        return Money.string(value, code: currencyCode, symbol: currency.symbol, fractionDigits: fractionDigits)
    }

    func displayDecimal(_ value: Decimal, fractionDigits: Int = 2) -> String {
        guard !hideAmounts else { return "•••••" }
        return Money.format(value, code: currencyCode, symbol: currency.symbol, fractionDigits: fractionDigits)
    }

    private enum Keys {
        static let currencyCode = "pref.currencyCode"
        static let firstDayOfMonth = "pref.firstDayOfMonth"
        static let defaultStrategy = "pref.defaultStrategy"
        static let hideAmounts = "pref.hideAmounts"
        static let monthlyReminder = "pref.monthlyReminder"
        static let haptics = "pref.haptics"
    }
}
