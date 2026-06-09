import Foundation
import SwiftUI

/// Weight display preference, persisted in Settings.
enum WeightUnit: String, CaseIterable, Identifiable, Codable {
    case kg, lb
    var id: String { rawValue }
    var label: String { self == .kg ? "Kilograms (kg)" : "Pounds (lb)" }
    var short: String { rawValue }
}

/// Length display preference, persisted in Settings.
enum LengthUnit: String, CaseIterable, Identifiable, Codable {
    case cm, inch
    var id: String { rawValue }
    var label: String { self == .cm ? "Centimeters (cm)" : "Inches (in)" }
    var short: String { self == .cm ? "cm" : "in" }
}

/// Pure conversion + formatting helpers. Storage is always canonical (kg, cm, %).
/// All conversions guard against nonsense (NaN / negative inputs collapse to 0).
enum Units {

    private static let lbPerKg = 2.2046226218
    private static let cmPerInch = 2.54

    /// Clamp to a usable number but PRESERVE sign (deltas/rates go negative).
    private static func finite(_ v: Double) -> Double { v.isFinite ? v : 0 }

    /// Clamp to non-negative (absolute measurement values can't be negative).
    private static func sane(_ v: Double) -> Double {
        (v.isFinite && v >= 0) ? v : 0
    }

    // MARK: - Weight (canonical kg). Sign-preserving so deltas convert correctly.

    static func kgToDisplay(_ kg: Double, unit: WeightUnit) -> Double {
        let v = finite(kg)
        return unit == .kg ? v : v * lbPerKg
    }

    static func displayToKg(_ value: Double, unit: WeightUnit) -> Double {
        let v = finite(value)
        return unit == .kg ? v : v / lbPerKg
    }

    // MARK: - Length (canonical cm). Sign-preserving.

    static func cmToDisplay(_ cm: Double, unit: LengthUnit) -> Double {
        let v = finite(cm)
        return unit == .cm ? v : v / cmPerInch
    }

    static func displayToCm(_ value: Double, unit: LengthUnit) -> Double {
        let v = finite(value)
        return unit == .cm ? v : v * cmPerInch
    }

    // MARK: - Per-metric display

    /// Convert a canonical *absolute* metric value into the user's preferred unit.
    /// Absolute readings are clamped non-negative.
    static func displayValue(_ canonical: Double, type: MetricType,
                             weightUnit: WeightUnit, lengthUnit: LengthUnit) -> Double {
        let safe = sane(canonical)
        switch type.category {
        case .mass:    return kgToDisplay(safe, unit: weightUnit)
        case .length:  return cmToDisplay(safe, unit: lengthUnit)
        case .percent: return safe
        }
    }

    /// Convert an entered display value back to canonical for storage.
    static func canonicalValue(_ display: Double, type: MetricType,
                               weightUnit: WeightUnit, lengthUnit: LengthUnit) -> Double {
        switch type.category {
        case .mass:    return displayToKg(display, unit: weightUnit)
        case .length:  return displayToCm(display, unit: lengthUnit)
        case .percent: return sane(display)
        }
    }

    /// Convert a canonical *delta* (which may be negative) to display units,
    /// preserving sign. Used for change/rate readouts.
    static func displayDelta(_ canonical: Double, type: MetricType,
                             weightUnit: WeightUnit, lengthUnit: LengthUnit) -> Double {
        guard canonical.isFinite else { return 0 }
        let sign: Double = canonical < 0 ? -1 : 1
        let magnitude = displayValue(abs(canonical), type: type,
                                     weightUnit: weightUnit, lengthUnit: lengthUnit)
        return sign * magnitude
    }

    /// Unit suffix string for a metric type given preferences.
    static func suffix(for type: MetricType, weightUnit: WeightUnit, lengthUnit: LengthUnit) -> String {
        switch type.category {
        case .mass:    return weightUnit.short
        case .length:  return lengthUnit.short
        case .percent: return "%"
        }
    }

    // MARK: - Formatting

    /// Formats a canonical metric value for display, e.g. "72.4 kg" or "31.5 in".
    static func formatted(_ canonical: Double, type: MetricType,
                          weightUnit: WeightUnit, lengthUnit: LengthUnit,
                          showUnit: Bool = true) -> String {
        let v = displayValue(canonical, type: type, weightUnit: weightUnit, lengthUnit: lengthUnit)
        let num = number(v)
        return showUnit ? "\(num) \(suffix(for: type, weightUnit: weightUnit, lengthUnit: lengthUnit))" : num
    }

    /// Formats a canonical weight (kg) for display, e.g. "159.8 lb".
    static func formattedWeight(_ kg: Double, unit: WeightUnit, showUnit: Bool = true) -> String {
        let v = kgToDisplay(kg, unit: unit)
        return showUnit ? "\(number(v)) \(unit.short)" : number(v)
    }

    /// One-decimal number string, trimming a trailing ".0".
    static func number(_ v: Double) -> String {
        let value = sane(v)
        if (value * 10).rounded() == (value.rounded() * 10) {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }

    /// Signed delta string, e.g. "+1.2" / "-3.0" / "0".
    static func signed(_ v: Double) -> String {
        guard v.isFinite else { return "0" }
        if abs(v) < 0.05 { return "0" }
        let body = number(abs(v))
        return v > 0 ? "+\(body)" : "-\(body)"
    }
}
