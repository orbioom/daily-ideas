import Foundation

/// Display unit for glucose. Canonical storage is always mg/dL.
enum GlucoseUnit: String, Codable, CaseIterable, Identifiable {
    case mgdl = "mg/dL"
    case mmol = "mmol/L"

    var id: String { rawValue }

    var label: String { rawValue }

    /// Conversion divisor from mg/dL to mmol/L.
    static let mmolDivisor: Double = 18.0182

    /// Convert a canonical mg/dL value into this unit's numeric value.
    func value(fromMgdl mgdl: Double) -> Double {
        switch self {
        case .mgdl: return mgdl
        case .mmol: return mgdl / Self.mmolDivisor
        }
    }

    /// Convert a value expressed in this unit back to canonical mg/dL.
    func mgdl(fromValue value: Double) -> Double {
        switch self {
        case .mgdl: return value
        case .mmol: return value * Self.mmolDivisor
        }
    }

    /// Decimal places appropriate for the unit.
    var fractionDigits: Int {
        switch self {
        case .mgdl: return 0
        case .mmol: return 1
        }
    }

    /// Sensible step for steppers / quick adjustments in this unit.
    var step: Double {
        switch self {
        case .mgdl: return 1
        case .mmol: return 0.1
        }
    }
}
