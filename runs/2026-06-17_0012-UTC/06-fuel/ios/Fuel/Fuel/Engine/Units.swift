import Foundation

/// Weight unit for display. Canonical storage is always kilograms.
enum WeightUnit: String, CaseIterable, Identifiable, Codable {
    case kg
    case lb
    var id: String { rawValue }

    var label: String { self == .kg ? "kg" : "lb" }

    /// Convert a canonical kilogram value into this display unit.
    func fromKg(_ kg: Double) -> Double {
        self == .kg ? kg : kg * 2.2046226218
    }

    /// Convert a value expressed in this display unit back into canonical kilograms.
    func toKg(_ value: Double) -> Double {
        self == .kg ? value : value / 2.2046226218
    }

    /// A sensible step for a stepper / slider in this unit.
    var step: Double { self == .kg ? 0.1 : 0.2 }
}

/// Height unit for display. Canonical storage is always centimeters.
enum HeightUnit: String, CaseIterable, Identifiable, Codable {
    case cm
    case ftIn
    var id: String { rawValue }

    var label: String { self == .cm ? "cm" : "ft / in" }
}

/// A height expressed as feet + inches, used only for display/editing.
struct FeetInches: Equatable {
    var feet: Int
    var inches: Int

    var totalInches: Double { Double(feet) * 12.0 + Double(inches) }

    var cm: Double { totalInches * 2.54 }

    static func fromCm(_ cm: Double) -> FeetInches {
        let totalInches = max(0, cm / 2.54)
        let rounded = Int(totalInches.rounded())
        let feet = rounded / 12
        let inches = rounded % 12
        return FeetInches(feet: feet, inches: inches)
    }
}

/// Biological sex used by the BMR formulas.
enum Sex: String, CaseIterable, Identifiable, Codable {
    case male
    case female
    var id: String { rawValue }
    var label: String { self == .male ? "Male" : "Female" }
}

/// Activity level → maintenance multiplier on BMR.
enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
    case sedentary
    case light
    case moderate
    case very
    case extra
    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light:     return 1.375
        case .moderate:  return 1.55
        case .very:      return 1.725
        case .extra:     return 1.9
        }
    }

    var title: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light:     return "Lightly active"
        case .moderate:  return "Moderately active"
        case .very:      return "Very active"
        case .extra:     return "Extra active"
        }
    }

    var detail: String {
        switch self {
        case .sedentary: return "Little or no exercise, desk job"
        case .light:     return "Light exercise 1–3 days/week"
        case .moderate:  return "Moderate exercise 3–5 days/week"
        case .very:      return "Hard exercise 6–7 days/week"
        case .extra:     return "Physical job or 2× training"
        }
    }
}

/// The user's current phase / objective.
enum Goal: String, CaseIterable, Identifiable, Codable {
    case cut
    case maintain
    case bulk
    var id: String { rawValue }

    var title: String {
        switch self {
        case .cut:      return "Cut"
        case .maintain: return "Maintain"
        case .bulk:     return "Lean bulk"
        }
    }

    var verb: String {
        switch self {
        case .cut:      return "Losing"
        case .maintain: return "Maintaining"
        case .bulk:     return "Gaining"
        }
    }

    /// +1 gain, -1 loss, 0 maintain — sign of the intended weight change.
    var direction: Double {
        switch self {
        case .cut:      return -1
        case .maintain: return 0
        case .bulk:     return 1
        }
    }

    var symbol: String {
        switch self {
        case .cut:      return "arrow.down.right"
        case .maintain: return "equal"
        case .bulk:     return "arrow.up.right"
        }
    }
}

/// BMR estimation formula.
enum BMRFormula: String, CaseIterable, Identifiable, Codable {
    case mifflin
    case katch
    var id: String { rawValue }

    var title: String { self == .mifflin ? "Mifflin-St Jeor" : "Katch-McArdle" }
    var detail: String {
        self == .mifflin
            ? "Standard estimate from height, weight, age & sex."
            : "Uses lean body mass — needs body-fat %."
    }
}

/// Diet style — drives the macro split preset.
enum DietStyle: String, CaseIterable, Identifiable, Codable {
    case balanced
    case highProtein
    case lowCarb
    case keto
    case custom
    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced:    return "Balanced"
        case .highProtein: return "High protein"
        case .lowCarb:     return "Low carb"
        case .keto:        return "Keto"
        case .custom:      return "Custom"
        }
    }

    var detail: String {
        switch self {
        case .balanced:    return "Even split across all three macros"
        case .highProtein: return "Protein-forward for training & satiety"
        case .lowCarb:     return "Fewer carbs, more fat & protein"
        case .keto:        return "Very low carb (~5%), high fat"
        case .custom:      return "Set your own protein & fat per kg"
        }
    }
}
