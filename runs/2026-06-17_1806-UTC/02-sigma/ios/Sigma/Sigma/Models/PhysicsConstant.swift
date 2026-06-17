import Foundation

/// A scientific/physics constant offered by the Pro Constants library.
struct PhysicsConstant: Identifiable, Hashable {
    let symbol: String
    let name: String
    let value: Double
    let unit: String
    var id: String { symbol + name }

    /// A plain-text value the calculator can insert into an expression.
    var insertableValue: String {
        // Use a high-precision, locale-independent representation.
        if value == value.rounded() && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        return String(value)
    }
}

/// The curated library of ~16 constants (Pro feature).
enum PhysicsConstants {
    static let all: [PhysicsConstant] = [
        PhysicsConstant(symbol: "c", name: "Speed of light", value: 299792458, unit: "m/s"),
        PhysicsConstant(symbol: "g", name: "Standard gravity", value: 9.80665, unit: "m/s²"),
        PhysicsConstant(symbol: "G", name: "Gravitational constant", value: 6.67430e-11, unit: "m³/kg·s²"),
        PhysicsConstant(symbol: "h", name: "Planck constant", value: 6.62607015e-34, unit: "J·s"),
        PhysicsConstant(symbol: "ħ", name: "Reduced Planck", value: 1.054571817e-34, unit: "J·s"),
        PhysicsConstant(symbol: "Nₐ", name: "Avogadro constant", value: 6.02214076e23, unit: "1/mol"),
        PhysicsConstant(symbol: "k", name: "Boltzmann constant", value: 1.380649e-23, unit: "J/K"),
        PhysicsConstant(symbol: "R", name: "Gas constant", value: 8.314462618, unit: "J/mol·K"),
        PhysicsConstant(symbol: "e", name: "Elementary charge", value: 1.602176634e-19, unit: "C"),
        PhysicsConstant(symbol: "mₑ", name: "Electron mass", value: 9.1093837015e-31, unit: "kg"),
        PhysicsConstant(symbol: "mₚ", name: "Proton mass", value: 1.67262192369e-27, unit: "kg"),
        PhysicsConstant(symbol: "ε₀", name: "Vacuum permittivity", value: 8.8541878128e-12, unit: "F/m"),
        PhysicsConstant(symbol: "μ₀", name: "Vacuum permeability", value: 1.25663706212e-6, unit: "N/A²"),
        PhysicsConstant(symbol: "σ", name: "Stefan–Boltzmann", value: 5.670374419e-8, unit: "W/m²·K⁴"),
        PhysicsConstant(symbol: "F", name: "Faraday constant", value: 96485.33212, unit: "C/mol"),
        PhysicsConstant(symbol: "atm", name: "Standard atmosphere", value: 101325, unit: "Pa")
    ]
}
