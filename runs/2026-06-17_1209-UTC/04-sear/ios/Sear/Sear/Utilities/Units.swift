import Foundation

/// Temperatures are canonical in Celsius (Double) everywhere in the model.
/// Weights are canonical in kilograms. These helpers convert for display only.
enum Units {

    // MARK: Temperature

    static func cToF(_ c: Double) -> Double { c * 9.0 / 5.0 + 32.0 }
    static func fToC(_ f: Double) -> Double { (f - 32.0) * 5.0 / 9.0 }

    /// A temperature string in the user's chosen unit, e.g. "74°C" or "165°F".
    static func temp(_ celsius: Double, fahrenheit: Bool) -> String {
        if fahrenheit {
            return "\(Int(cToF(celsius).rounded()))°F"
        } else {
            return "\(Int(celsius.rounded()))°C"
        }
    }

    /// The bare numeral (no unit suffix) for big-display temperatures.
    static func tempNumeral(_ celsius: Double, fahrenheit: Bool) -> String {
        fahrenheit ? "\(Int(cToF(celsius).rounded()))" : "\(Int(celsius.rounded()))"
    }

    static func unitSuffix(fahrenheit: Bool) -> String { fahrenheit ? "°F" : "°C" }

    // MARK: Weight

    static func kgToLb(_ kg: Double) -> Double { kg * 2.2046226218 }
    static func lbToKg(_ lb: Double) -> Double { lb / 2.2046226218 }

    /// A weight string in the user's chosen unit, e.g. "2.3 kg" or "5.1 lb".
    static func weight(_ kg: Double, pounds: Bool) -> String {
        if pounds {
            return String(format: "%.1f lb", kgToLb(kg))
        } else {
            return String(format: "%.2f kg", kg)
        }
    }

    static func weightUnit(pounds: Bool) -> String { pounds ? "lb" : "kg" }
}
