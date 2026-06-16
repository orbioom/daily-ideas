import Foundation

/// A measurement unit known to Galley. Volume and weight units carry a canonical
/// conversion factor (milliliters for volume, grams for weight).
enum MeasureUnit: String, CaseIterable, Identifiable, Codable, Hashable {
    // Volume
    case cup
    case tablespoon
    case teaspoon
    case fluidOunce
    case milliliter
    case liter
    // Weight
    case gram
    case ounce
    case pound
    case kilogram

    var id: String { rawValue }

    enum Kind: String { case volume, weight }

    var kind: Kind {
        switch self {
        case .cup, .tablespoon, .teaspoon, .fluidOunce, .milliliter, .liter:
            return .volume
        case .gram, .ounce, .pound, .kilogram:
            return .weight
        }
    }

    /// Short display abbreviation.
    var abbreviation: String {
        switch self {
        case .cup: return "cup"
        case .tablespoon: return "tbsp"
        case .teaspoon: return "tsp"
        case .fluidOunce: return "fl oz"
        case .milliliter: return "ml"
        case .liter: return "L"
        case .gram: return "g"
        case .ounce: return "oz"
        case .pound: return "lb"
        case .kilogram: return "kg"
        }
    }

    /// Full human name.
    var fullName: String {
        switch self {
        case .cup: return "Cup"
        case .tablespoon: return "Tablespoon"
        case .teaspoon: return "Teaspoon"
        case .fluidOunce: return "Fluid Ounce"
        case .milliliter: return "Milliliter"
        case .liter: return "Liter"
        case .gram: return "Gram"
        case .ounce: return "Ounce"
        case .pound: return "Pound"
        case .kilogram: return "Kilogram"
        }
    }

    /// Canonical milliliters for one of this volume unit. `nil` for weight units.
    var millilitersPerUnit: Double? {
        switch self {
        case .cup: return 236.588
        case .tablespoon: return 14.787
        case .teaspoon: return 4.929
        case .fluidOunce: return 29.574
        case .milliliter: return 1.0
        case .liter: return 1000.0
        default: return nil
        }
    }

    /// Canonical grams for one of this weight unit. `nil` for volume units.
    var gramsPerUnit: Double? {
        switch self {
        case .gram: return 1.0
        case .ounce: return 28.3495
        case .pound: return 453.592
        case .kilogram: return 1000.0
        default: return nil
        }
    }

    static var volumeUnits: [MeasureUnit] {
        allCases.filter { $0.kind == .volume }
    }

    static var weightUnits: [MeasureUnit] {
        allCases.filter { $0.kind == .weight }
    }
}
