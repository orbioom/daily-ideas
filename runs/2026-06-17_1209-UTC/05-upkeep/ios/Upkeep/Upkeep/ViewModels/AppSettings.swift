import SwiftUI

/// Persisted user preferences that actually change behavior across the app.
///
/// Values are mirrored to `UserDefaults` via `didSet` and surfaced as `@Published`
/// so that every observing view recomputes when a preference changes.
@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let hemisphere = "hemisphereRaw"
        static let dueSoonDays = "dueSoonDays"
        static let currency = "currencySymbol"
        static let reminders = "remindersEnabled"
        static let haptics = "hapticsEnabled"
    }

    @Published var hemisphereRaw: String {
        didSet { defaults.set(hemisphereRaw, forKey: Key.hemisphere) }
    }
    @Published var dueSoonDays: Int {
        didSet { defaults.set(dueSoonDays, forKey: Key.dueSoonDays) }
    }
    @Published var currencySymbol: String {
        didSet { defaults.set(currencySymbol, forKey: Key.currency) }
    }
    @Published var remindersEnabled: Bool {
        didSet { defaults.set(remindersEnabled, forKey: Key.reminders) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.haptics) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hemisphereRaw = defaults.string(forKey: Key.hemisphere) ?? Hemisphere.northern.rawValue
        let storedWindow = defaults.object(forKey: Key.dueSoonDays) as? Int
        self.dueSoonDays = storedWindow ?? 14
        self.currencySymbol = defaults.string(forKey: Key.currency) ?? "$"
        self.remindersEnabled = defaults.bool(forKey: Key.reminders)
        let storedHaptics = defaults.object(forKey: Key.haptics) as? Bool
        self.hapticsEnabled = storedHaptics ?? true
    }

    var hemisphere: Hemisphere {
        get { Hemisphere(rawValue: hemisphereRaw) ?? .northern }
        set { hemisphereRaw = newValue.rawValue }
    }

    /// Clamp the due-soon window into a sane range for the UI stepper.
    var clampedDueSoonDays: Int {
        min(max(dueSoonDays, 1), 60)
    }

    /// Format a money amount using the chosen currency symbol, via Decimal for precision.
    func formatMoney(_ value: Double) -> String {
        let symbol = currencySymbol.isEmpty ? "$" : currencySymbol
        let decimal = Decimal(value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let number = formatter.string(from: decimal as NSDecimalNumber) ?? String(format: "%.2f", value)
        return symbol + number
    }

    /// Whole-unit money for compact chart labels.
    func formatMoneyShort(_ value: Double) -> String {
        let symbol = currencySymbol.isEmpty ? "$" : currencySymbol
        return symbol + String(Int(value.rounded()))
    }
}
