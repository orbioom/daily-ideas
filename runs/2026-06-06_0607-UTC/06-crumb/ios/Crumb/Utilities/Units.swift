import Foundation

/// Pure conversion + formatting helpers for the user-selectable units. Canonical storage
/// is always metric (grams, °C); these convert only at the display boundary.
enum Units {

    enum Mass: String, CaseIterable, Identifiable {
        case grams, ounces
        var id: String { rawValue }
        var title: String { self == .grams ? "Grams (g)" : "Ounces (oz)" }
        var suffix: String { self == .grams ? "g" : "oz" }
    }

    enum Temperature: String, CaseIterable, Identifiable {
        case celsius, fahrenheit
        var id: String { rawValue }
        var title: String { self == .celsius ? "Celsius (°C)" : "Fahrenheit (°F)" }
        var suffix: String { self == .celsius ? "°C" : "°F" }
    }

    private static let gramsPerOunce = 28.349523125

    /// Format a gram value for display in the chosen mass unit.
    static func mass(_ grams: Double, unit: Mass) -> String {
        guard grams.isFinite else { return "—" }
        switch unit {
        case .grams:
            return BakersMath.displayGrams(grams)
        case .ounces:
            let oz = max(0, grams) / gramsPerOunce
            return String(format: oz >= 10 ? "%.1f" : "%.2f", oz)
        }
    }

    /// Format a gram value with its unit suffix (e.g. "750 g" or "26.46 oz").
    static func massWithSuffix(_ grams: Double, unit: Mass) -> String {
        "\(mass(grams, unit: unit)) \(unit.suffix)"
    }

    /// Convert a canonical °C value into the chosen temperature unit's numeric value.
    static func temperatureValue(_ celsius: Double, unit: Temperature) -> Double {
        switch unit {
        case .celsius:    return celsius
        case .fahrenheit: return celsius * 9.0 / 5.0 + 32.0
        }
    }

    /// Convert a value entered in the chosen unit back to canonical °C.
    static func celsius(from value: Double, unit: Temperature) -> Double {
        switch unit {
        case .celsius:    return value
        case .fahrenheit: return (value - 32.0) * 5.0 / 9.0
        }
    }

    /// Format a canonical °C value for display in the chosen unit, with suffix.
    static func temperature(_ celsius: Double, unit: Temperature) -> String {
        guard celsius.isFinite else { return "—" }
        let v = temperatureValue(celsius, unit: unit)
        return "\(Int(v.rounded()))\(unit.suffix)"
    }
}
