import Foundation

enum VolumeUnit: String, CaseIterable, Identifiable {
    case ml, floz
    var id: String { rawValue }
    var label: String { self == .ml ? "Millilitres (ml)" : "Fluid ounces (oz)" }
    var short: String { self == .ml ? "ml" : "oz" }
}

enum Units {
    static let mlPerFloz = 29.5735

    /// Convert a canonical ml value to the display unit.
    static func display(_ ml: Double, as unit: VolumeUnit) -> Double {
        unit == .ml ? ml : ml / mlPerFloz
    }

    /// Convert a display-unit value back to canonical ml.
    static func toML(_ value: Double, from unit: VolumeUnit) -> Double {
        unit == .ml ? value : value * mlPerFloz
    }

    /// Whole-number-ish display string with unit, e.g. "1,250 ml" or "42 oz".
    static func string(_ ml: Double, as unit: VolumeUnit) -> String {
        let v = display(ml, as: unit)
        let rounded = unit == .ml ? (v / 10).rounded() * 10 : v.rounded()
        return "\(Int(rounded)) \(unit.short)"
    }

    /// Liters / large display for the ring center, e.g. "1.25 L" or "42 oz".
    static func headline(_ ml: Double, as unit: VolumeUnit) -> String {
        if unit == .ml {
            let liters = ml / 1000
            return String(format: "%.2f L", liters)
        } else {
            return "\(Int(display(ml, as: .floz).rounded())) oz"
        }
    }

    /// Common quick-add increments for the "+ custom" stepper, in ml.
    static func increments(for unit: VolumeUnit) -> [Double] {
        unit == .ml ? [100, 250, 500] : [toML(8, from: .floz), toML(12, from: .floz), toML(16, from: .floz)]
    }
}
