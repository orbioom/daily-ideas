import Foundation

/// Weight display unit. Storage is always kilograms; these convert for display & input.
enum MassUnit: String, CaseIterable, Identifiable, Codable {
    case kg
    case lb
    var id: String { rawValue }
    var label: String { self == .kg ? "Kilograms (kg)" : "Pounds (lb)" }
    var short: String { rawValue }
}

/// Length display unit. Storage is always centimeters.
enum LengthUnit: String, CaseIterable, Identifiable, Codable {
    case cm
    case inch
    var id: String { rawValue }
    var label: String { self == .cm ? "Centimeters (cm)" : "Inches (in)" }
    var short: String { self == .cm ? "cm" : "in" }
}

/// Pure conversion helpers between stored SI units and display units.
enum UnitConvert {
    private static let kgPerLb = 0.45359237
    private static let cmPerInch = 2.54

    // Weight: kg <-> lb
    static func kgToLb(_ kg: Double) -> Double { kg / kgPerLb }
    static func lbToKg(_ lb: Double) -> Double { lb * kgPerLb }

    // Length: cm <-> in
    static func cmToInch(_ cm: Double) -> Double { cm / cmPerInch }
    static func inchToCm(_ inch: Double) -> Double { inch * cmPerInch }

    /// Convert a stored SI value into the chosen display unit for a measure.
    static func display(_ siValue: Double, measure: GrowthMeasure, mass: MassUnit, length: LengthUnit) -> Double {
        switch measure {
        case .weight:
            return mass == .kg ? siValue : kgToLb(siValue)
        case .height, .head:
            return length == .cm ? siValue : cmToInch(siValue)
        }
    }

    /// Convert a display-unit value back into the stored SI value for a measure.
    static func toSI(_ displayValue: Double, measure: GrowthMeasure, mass: MassUnit, length: LengthUnit) -> Double {
        switch measure {
        case .weight:
            return mass == .kg ? displayValue : lbToKg(displayValue)
        case .height, .head:
            return length == .cm ? displayValue : inchToCm(displayValue)
        }
    }

    /// The unit label string for a measure under the chosen settings.
    static func unitShort(for measure: GrowthMeasure, mass: MassUnit, length: LengthUnit) -> String {
        switch measure {
        case .weight: return mass.short
        case .height, .head: return length.short
        }
    }

    /// Format an SI value for display, with unit, e.g. "7.9 kg" or "17.4 lb".
    static func format(_ siValue: Double, measure: GrowthMeasure, mass: MassUnit, length: LengthUnit) -> String {
        let v = display(siValue, measure: measure, mass: mass, length: length)
        let unit = unitShort(for: measure, mass: mass, length: length)
        let decimals = (measure == .weight && mass == .lb) ? 1 : 1
        return String(format: "%.\(decimals)f %@", v, unit)
    }
}
