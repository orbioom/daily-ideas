import SwiftUI

enum ElementCategory: String, CaseIterable, Identifiable, Codable {
    case alkaliMetal = "Alkali Metal"
    case alkalineEarth = "Alkaline Earth"
    case transitionMetal = "Transition Metal"
    case postTransition = "Post-Transition Metal"
    case metalloid = "Metalloid"
    case nonmetal = "Nonmetal"
    case halogen = "Halogen"
    case nobleGas = "Noble Gas"
    case lanthanide = "Lanthanide"
    case actinide = "Actinide"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .alkaliMetal:    return Color(red: 0.95, green: 0.30, blue: 0.30)
        case .alkalineEarth:  return Color(red: 0.95, green: 0.60, blue: 0.25)
        case .transitionMetal: return Color(red: 0.95, green: 0.85, blue: 0.30)
        case .postTransition: return Color(red: 0.40, green: 0.80, blue: 0.40)
        case .metalloid:      return Color(red: 0.25, green: 0.70, blue: 0.65)
        case .nonmetal:       return Color(red: 0.30, green: 0.55, blue: 0.90)
        case .halogen:        return Color(red: 0.65, green: 0.35, blue: 0.90)
        case .nobleGas:       return Color(red: 0.90, green: 0.30, blue: 0.75)
        case .lanthanide:     return Color(red: 0.55, green: 0.75, blue: 0.95)
        case .actinide:       return Color(red: 0.75, green: 0.55, blue: 0.95)
        }
    }

    var colorBlindColor: Color {
        switch self {
        case .alkaliMetal:    return Color(red: 0.80, green: 0.40, blue: 0.00)
        case .alkalineEarth:  return Color(red: 0.90, green: 0.60, blue: 0.00)
        case .transitionMetal: return Color(red: 0.60, green: 0.60, blue: 0.60)
        case .postTransition: return Color(red: 0.00, green: 0.60, blue: 0.50)
        case .metalloid:      return Color(red: 0.00, green: 0.45, blue: 0.70)
        case .nonmetal:       return Color(red: 0.00, green: 0.75, blue: 0.75)
        case .halogen:        return Color(red: 0.80, green: 0.40, blue: 0.00)
        case .nobleGas:       return Color(red: 0.80, green: 0.60, blue: 0.70)
        case .lanthanide:     return Color(red: 0.35, green: 0.70, blue: 0.90)
        case .actinide:       return Color(red: 0.60, green: 0.50, blue: 0.80)
        }
    }

    func displayColor(colorBlind: Bool) -> Color {
        colorBlind ? colorBlindColor : color
    }
}
