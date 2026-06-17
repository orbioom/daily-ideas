import Foundation

/// Safe conversions between canonical storage units (kg, cm, percent) and the
/// user's chosen display units. Percent is never converted.
enum Units {
    static let kgPerLb = 0.45359237
    static let cmPerInch = 2.54

    // MARK: Canonical -> display

    static func displayValue(canonical: Double, kind: UnitKind, system: UnitSystem) -> Double {
        switch kind {
        case .mass:
            return system == .metric ? canonical : canonical / kgPerLb
        case .length:
            return system == .metric ? canonical : canonical / cmPerInch
        case .percent:
            return canonical
        }
    }

    // MARK: Display -> canonical

    static func canonicalValue(display: Double, kind: UnitKind, system: UnitSystem) -> Double {
        switch kind {
        case .mass:
            return system == .metric ? display : display * kgPerLb
        case .length:
            return system == .metric ? display : display * cmPerInch
        case .percent:
            return display
        }
    }

    static func unitLabel(kind: UnitKind, system: UnitSystem) -> String {
        switch kind {
        case .mass: return system.massUnit
        case .length: return system.lengthUnit
        case .percent: return "%"
        }
    }

    /// Sensible decimal places for display per kind.
    static func fractionDigits(kind: UnitKind) -> Int {
        switch kind {
        case .mass: return 1
        case .length: return 1
        case .percent: return 1
        }
    }

    static func formatted(canonical: Double, kind: UnitKind, system: UnitSystem) -> String {
        let v = displayValue(canonical: canonical, kind: kind, system: system)
        return number(v, digits: fractionDigits(kind: kind))
    }

    static func number(_ value: Double, digits: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = digits
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.\(digits)f", value)
    }

    /// Plausible display-value bounds for input validation per kind.
    static func plausibleRange(kind: UnitKind, system: UnitSystem) -> ClosedRange<Double> {
        switch kind {
        case .mass:
            return system == .metric ? 20...300 : 44...660
        case .length:
            return system == .metric ? 5...250 : 2...100
        case .percent:
            return 1...70
        }
    }
}
