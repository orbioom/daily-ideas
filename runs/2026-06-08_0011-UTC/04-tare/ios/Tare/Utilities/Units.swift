import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb, st   // st = stones & pounds (UK)
    var id: String { rawValue }

    var label: String {
        switch self {
        case .kg: return "Kilograms (kg)"
        case .lb: return "Pounds (lb)"
        case .st: return "Stones (st)"
        }
    }
    var short: String {
        switch self { case .kg: return "kg"; case .lb: return "lb"; case .st: return "st" }
    }
}

/// All conversions go through kilograms.
enum Units {
    static let lbPerKg = 2.2046226218

    static func fromKg(_ kg: Double, to unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return kg
        case .lb, .st: return kg * lbPerKg
        }
    }

    static func toKg(_ value: Double, from unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return value
        case .lb, .st: return value / lbPerKg
        }
    }

    /// Human display for a kg value in the chosen unit.
    static func display(_ kg: Double, unit: WeightUnit, decimals: Int = 1) -> String {
        switch unit {
        case .kg:
            return String(format: "%.\(decimals)f kg", kg)
        case .lb:
            return String(format: "%.\(decimals)f lb", kg * lbPerKg)
        case .st:
            let totalLb = kg * lbPerKg
            let stones = Int(totalLb / 14)
            let lbs = totalLb - Double(stones) * 14
            return "\(stones) st \(String(format: "%.1f", lbs)) lb"
        }
    }

    /// Compact numeric (no unit suffix) for chart axes / big numbers.
    static func value(_ kg: Double, unit: WeightUnit, decimals: Int = 1) -> Double {
        fromKg(kg, to: unit).rounded(toPlaces: decimals)
    }

    static func deltaDisplay(_ kgDelta: Double, unit: WeightUnit) -> String {
        let v = fromKg(abs(kgDelta), to: unit)
        let sign = kgDelta > 0.0001 ? "+" : (kgDelta < -0.0001 ? "−" : "")
        return "\(sign)\(String(format: "%.1f", v)) \(unit == .st ? "lb" : unit.short)"
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let m = pow(10.0, Double(places))
        return (self * m).rounded() / m
    }
}
