import Foundation

enum IngredientCategory: String, CaseIterable, Codable {
    case active = "Active"
    case emollient = "Emollient/Occlusive"
    case humectant = "Humectant"
    case preservative = "Preservative"
    case emulsifier = "Emulsifier"
    case surfactant = "Surfactant"
    case sunscreen = "Sunscreen"
    case fragrance = "Fragrance"
    case soothing = "Soothing"
    case exfoliant = "Exfoliant"
    case colorant = "Colorant"
    case thickener = "Thickener"
    case solvent = "Solvent"
    case phAdjuster = "pH Adjuster"
    case problematic = "Flagged"

    var systemImage: String {
        switch self {
        case .active: return "bolt.circle.fill"
        case .emollient: return "drop.fill"
        case .humectant: return "humidity.fill"
        case .preservative: return "shield.fill"
        case .emulsifier: return "arrow.triangle.2.circlepath"
        case .surfactant: return "bubbles.and.sparkles.fill"
        case .sunscreen: return "sun.max.fill"
        case .fragrance: return "wind"
        case .soothing: return "leaf.fill"
        case .exfoliant: return "sparkles"
        case .colorant: return "paintpalette.fill"
        case .thickener: return "cylinder.fill"
        case .solvent: return "flask.fill"
        case .phAdjuster: return "plusminus.circle.fill"
        case .problematic: return "exclamationmark.triangle.fill"
        }
    }
}
