import SwiftUI

/// Supported display currencies. Raw value is the ISO code; we keep a symbol too.
enum CurrencyOption: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    case inr = "INR"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .usd, .cad, .aud: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .inr: return "₹"
        }
    }

    var label: String { "\(rawValue) (\(symbol))" }
}

/// How term lengths are displayed/edited.
enum TermUnit: String, CaseIterable, Identifiable {
    case years
    case months
    var id: String { rawValue }
    var label: String { self == .years ? "Years" : "Months" }
}

/// Observable wrapper over the small persisted preferences. Created once at the
/// root and injected via `@Environment` so every screen reads the same store.
@Observable
final class AppSettings {
    var currencyCode: String {
        didSet { UserDefaults.standard.set(currencyCode, forKey: Keys.currency) }
    }
    var defaultTermMonths: Int {
        didSet { UserDefaults.standard.set(defaultTermMonths, forKey: Keys.defaultTerm) }
    }
    var defaultExtraMonthly: Double {
        didSet { UserDefaults.standard.set(defaultExtraMonthly, forKey: Keys.defaultExtra) }
    }
    var termUnitRaw: String {
        didSet { UserDefaults.standard.set(termUnitRaw, forKey: Keys.termUnit) }
    }
    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    var currency: CurrencyOption { CurrencyOption(rawValue: currencyCode) ?? .usd }
    var termUnit: TermUnit { TermUnit(rawValue: termUnitRaw) ?? .years }

    private enum Keys {
        static let currency = "pref.currencyCode"
        static let defaultTerm = "pref.defaultTermMonths"
        static let defaultExtra = "pref.defaultExtraMonthly"
        static let termUnit = "pref.termUnit"
        static let haptics = "pref.hapticsEnabled"
    }

    init() {
        let d = UserDefaults.standard
        self.currencyCode = d.string(forKey: Keys.currency) ?? CurrencyOption.usd.rawValue
        let storedTerm = d.integer(forKey: Keys.defaultTerm)
        self.defaultTermMonths = storedTerm > 0 ? storedTerm : 360
        self.defaultExtraMonthly = d.double(forKey: Keys.defaultExtra) // 0 default is fine
        self.termUnitRaw = d.string(forKey: Keys.termUnit) ?? TermUnit.years.rawValue
        // Default haptics ON, but respect a stored value if the key exists.
        if d.object(forKey: Keys.haptics) == nil {
            self.hapticsEnabled = true
        } else {
            self.hapticsEnabled = d.bool(forKey: Keys.haptics)
        }
    }
}
