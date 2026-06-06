import Foundation

/// Mass display unit for harvests. Stored in kg, displayed as chosen.
enum MassUnit: String, CaseIterable, Identifiable {
    case kg = "Kilograms", lb = "Pounds"
    var id: String { rawValue }
    var short: String { self == .kg ? "kg" : "lb" }
    private static let lbPerKg = 2.2046226218

    func fromKg(_ kg: Double) -> Double { self == .kg ? kg : kg * Self.lbPerKg }
    func toKg(_ value: Double) -> Double { self == .kg ? value : value / Self.lbPerKg }
    func format(kg: Double) -> String { String(format: "%.1f %@", fromKg(kg), short) }
}
