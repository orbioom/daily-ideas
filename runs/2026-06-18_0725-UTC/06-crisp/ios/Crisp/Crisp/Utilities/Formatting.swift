import Foundation

/// Shared, crash-proof formatting helpers for temps, times and weights.
enum Fmt {

    /// Formats a temperature held internally in °F into the user's chosen unit.
    static func temp(fahrenheit: Int, unit: TempUnit) -> String {
        switch unit {
        case .fahrenheit:
            return "\(fahrenheit)°F"
        case .celsius:
            let c = Int((Double(fahrenheit) - 32) * 5 / 9 + (fahrenheit >= 0 ? 0.5 : -0.5))
            return "\(c)°C"
        }
    }

    /// Just the numeric value (no unit suffix) for large hero displays.
    static func tempValue(fahrenheit: Int, unit: TempUnit) -> Int {
        switch unit {
        case .fahrenheit:
            return fahrenheit
        case .celsius:
            return Int((Double(fahrenheit) - 32) * 5 / 9 + (fahrenheit >= 0 ? 0.5 : -0.5))
        }
    }

    /// Whole minutes as a friendly "Xm" / "Xm Ys" string from total seconds.
    static func clock(seconds: Int) -> String {
        let s = max(0, seconds)
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }

    /// "18 min" style label from minutes.
    static func minutesLabel(_ minutes: Int) -> String {
        let m = max(0, minutes)
        return m == 1 ? "1 min" : "\(m) min"
    }

    /// Weight held internally in grams, formatted into the chosen unit.
    static func weight(grams: Double, unit: WeightUnit) -> String {
        switch unit {
        case .grams:
            return "\(Int(grams.rounded())) g"
        case .ounces:
            let oz = grams / 28.349523125
            return String(format: "%.1f oz", oz)
        }
    }
}
