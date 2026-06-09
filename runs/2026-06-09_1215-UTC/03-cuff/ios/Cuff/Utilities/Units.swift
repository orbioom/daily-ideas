import Foundation

/// Unit conversion. Canonical storage is kg (weight) and mg/dL (glucose); these
/// helpers convert to the user's chosen display units. Conversions are exact:
/// lb = kg × 2.2046, mmol/L = mg/dL ÷ 18.0.
enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var label: String { self == .kg ? "Kilograms (kg)" : "Pounds (lb)" }
    var short: String { self == .kg ? "kg" : "lb" }

    /// kg → display value in this unit.
    func fromKg(_ kg: Double) -> Double { self == .kg ? kg : kg * 2.2046 }
    /// display value in this unit → canonical kg.
    func toKg(_ value: Double) -> Double { self == .kg ? value : value / 2.2046 }

    static func from(_ raw: String) -> WeightUnit { WeightUnit(rawValue: raw) ?? .kg }
}

enum GlucoseUnit: String, CaseIterable, Identifiable {
    case mgdl, mmoll
    var id: String { rawValue }
    var label: String { self == .mgdl ? "mg/dL" : "mmol/L" }
    var short: String { self == .mgdl ? "mg/dL" : "mmol/L" }

    /// mg/dL → display value in this unit.
    func fromMgdl(_ mgdl: Double) -> Double { self == .mgdl ? mgdl : mgdl / 18.0 }
    /// display value in this unit → canonical mg/dL.
    func toMgdl(_ value: Double) -> Double { self == .mgdl ? value : value * 18.0 }

    static func from(_ raw: String) -> GlucoseUnit { GlucoseUnit(rawValue: raw) ?? .mgdl }
}
