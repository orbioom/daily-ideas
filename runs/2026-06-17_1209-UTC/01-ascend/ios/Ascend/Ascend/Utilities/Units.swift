import Foundation

/// Weight unit for display. Storage is always canonical kilograms.
enum WeightUnit: String, CaseIterable, Identifiable {
    case kg
    case lb
    var id: String { rawValue }

    var label: String { self == .kg ? "kg" : "lb" }

    /// Plate/bar increments feel natural per unit when nudging weights.
    var commonStepKg: Double { self == .kg ? 2.5 : 1.13398 } // ~2.5 lb
}

/// Pure conversion + formatting between canonical kg and the chosen display unit.
enum Units {
    static let kgPerLb = 0.45359237

    static func toDisplay(_ kg: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return kg
        case .lb: return kg / kgPerLb
        }
    }

    static func fromDisplay(_ value: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return value
        case .lb: return value * kgPerLb
        }
    }

    /// "60 kg" / "135 lb" — trims trailing .0, keeps up to one decimal otherwise.
    static func formatWeight(_ kg: Double, unit: WeightUnit) -> String {
        let v = toDisplay(kg, unit: unit)
        return trimmed(v) + " " + unit.label
    }

    /// Number only, no unit suffix (for big numerals where the unit is shown separately).
    static func formatNumber(_ kg: Double, unit: WeightUnit) -> String {
        trimmed(toDisplay(kg, unit: unit))
    }

    static func trimmed(_ v: Double) -> String {
        if abs(v.rounded() - v) < 0.05 {
            return String(Int(v.rounded()))
        }
        return String(format: "%.1f", v)
    }

    /// Round a kg weight to the nearest sensible plate increment (2.5 kg).
    static func roundToPlate(_ kg: Double, step: Double = 2.5) -> Double {
        guard step > 0 else { return max(kg, 0) }
        return max((kg / step).rounded() * step, 0)
    }
}
