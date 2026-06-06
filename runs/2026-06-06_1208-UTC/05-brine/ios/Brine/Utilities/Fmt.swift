import Foundation

/// Display/units helper. Temperature and salinity convert for display; all
/// other parameters use their canonical unit directly.
struct Units {
    var tempFahrenheit: Bool
    var salinitySG: Bool
}

enum Fmt {
    private static let sgPerPpt = 0.000754   // approx at reef temps

    /// Convert a canonical value to the user's display number.
    static func toDisplay(_ p: WaterParameter, _ value: Double, _ u: Units) -> Double {
        switch p {
        case .temperature: return u.tempFahrenheit ? value * 9 / 5 + 32 : value
        case .salinity: return u.salinitySG ? 1 + value * sgPerPpt : value
        default: return value
        }
    }
    /// Convert a display number back to canonical units.
    static func toCanonical(_ p: WaterParameter, _ display: Double, _ u: Units) -> Double {
        switch p {
        case .temperature: return u.tempFahrenheit ? (display - 32) * 5 / 9 : display
        case .salinity: return u.salinitySG ? (display - 1) / sgPerPpt : display
        default: return display
        }
    }
    /// Display unit label.
    static func unit(_ p: WaterParameter, _ u: Units) -> String {
        switch p {
        case .temperature: return u.tempFahrenheit ? "°F" : "°C"
        case .salinity: return u.salinitySG ? "SG" : "ppt"
        default: return p.unit
        }
    }
    static func decimals(_ p: WaterParameter, _ u: Units) -> Int {
        if p == .salinity && u.salinitySG { return 4 }
        return p.decimals
    }
    /// Full formatted value with unit.
    static func string(_ p: WaterParameter, _ value: Double, _ u: Units, withUnit: Bool = true) -> String {
        let d = toDisplay(p, value, u)
        let dec = decimals(p, u)
        let num = String(format: "%.\(dec)f", d)
        let unitStr = unit(p, u)
        return withUnit && !unitStr.isEmpty ? "\(num) \(unitStr)" : num
    }
    /// Ideal range as a friendly string in display units.
    static func idealString(_ p: WaterParameter, _ u: Units) -> String {
        let lo = toDisplay(p, p.ideal.lowerBound, u)
        let hi = toDisplay(p, p.ideal.upperBound, u)
        let dec = decimals(p, u)
        if lo == hi { return String(format: "%.\(dec)f", lo) }
        return String(format: "%.\(dec)f–%.\(dec)f", lo, hi)
    }
}
