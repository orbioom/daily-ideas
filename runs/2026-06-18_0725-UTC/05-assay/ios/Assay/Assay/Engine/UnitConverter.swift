import Foundation

/// Converts marker values between canonical and alternate units.
/// All conversions use the multiplicative factor defined on `AltUnit`:
/// `alternateValue = canonicalValue * factor`.
enum UnitConverter {

    /// Convert a raw recorded value (in `rawUnit`) into the marker's canonical
    /// unit. If the unit is unrecognized we assume it is already canonical.
    static func toCanonical(value: Double, rawUnit: String, marker: Biomarker) -> Double {
        guard value.isFinite else { return value }
        if rawUnit == marker.unit { return value }
        if let alt = marker.altUnit, rawUnit == alt.unit {
            guard alt.factor != 0 else { return value }
            return value / alt.factor
        }
        return value // unknown unit: treat as canonical, never crash
    }

    /// Convert a canonical value into the given alternate unit.
    static func fromCanonical(value: Double, to alt: AltUnit) -> Double {
        guard value.isFinite else { return value }
        return value * alt.factor
    }

    /// Convert a canonical value into a display value for the chosen unit.
    /// Passing nil means "display in canonical unit".
    static func display(canonical: Double, altUnit: AltUnit?) -> Double {
        guard let alt = altUnit else { return canonical }
        return fromCanonical(value: canonical, to: alt)
    }

    /// Convert a canonical range bound into the chosen display unit.
    static func displayBound(_ bound: Double?, altUnit: AltUnit?) -> Double? {
        guard let b = bound else { return nil }
        return display(canonical: b, altUnit: altUnit)
    }
}
