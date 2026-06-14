import SwiftUI

/// Olfactory family of a scent note. Drives swatch gradients and stats.
enum NoteFamily: String, Codable, CaseIterable, Identifiable {
    case citrus = "Citrus"
    case floral = "Floral"
    case woody = "Woody"
    case amber = "Amber"        // oriental / amber
    case fresh = "Fresh"
    case gourmand = "Gourmand"
    case spicy = "Spicy"
    case green = "Green"
    case fougere = "Fougère"
    case chypre = "Chypre"
    case aquatic = "Aquatic"
    case leather = "Leather"
    case musk = "Musk"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .citrus: return "sun.max"
        case .floral: return "camera.macro"
        case .woody: return "tree"
        case .amber: return "flame"
        case .fresh: return "wind"
        case .gourmand: return "birthday.cake"
        case .spicy: return "flame.fill"
        case .green: return "leaf"
        case .fougere: return "leaf.fill"
        case .chypre: return "circle.grid.2x2"
        case .aquatic: return "drop"
        case .leather: return "bag"
        case .musk: return "smoke"
        }
    }

    /// A dynamic hue per family for chips, donut slices, and swatch gradients.
    var hue: Color {
        switch self {
        case .citrus: return Color.dyn(0xD2A410, 0xE8C249)
        case .floral: return Color.dyn(0xC25C82, 0xE08CAB)
        case .woody: return Color.dyn(0x8A5A2B, 0xC79361)
        case .amber: return Color.dyn(0xC0701C, 0xE0A14F)
        case .fresh: return Color.dyn(0x3F9BA8, 0x73C3CE)
        case .gourmand: return Color.dyn(0xA56A3C, 0xD09A6E)
        case .spicy: return Color.dyn(0xB24A2C, 0xDC7E62)
        case .green: return Color.dyn(0x4F8A4A, 0x80C079)
        case .fougere: return Color.dyn(0x5C7A4A, 0x93B580)
        case .chypre: return Color.dyn(0x7A5C8A, 0xAE92BD)
        case .aquatic: return Color.dyn(0x3071A8, 0x6FA6D6)
        case .leather: return Color.dyn(0x6E4B30, 0xAB8161)
        case .musk: return Color.dyn(0x8E8675, 0xC2BBA9)
        }
    }

    /// Second hue used to build the soft swatch gradient.
    var hueDeep: Color {
        switch self {
        case .citrus: return Color.dyn(0xB8860B, 0xC9A634)
        case .floral: return Color.dyn(0x9C3E63, 0xC56F90)
        case .woody: return Color.dyn(0x6B4220, 0xA67A4C)
        case .amber: return Color.dyn(0x9E550F, 0xC98A3A)
        case .fresh: return Color.dyn(0x2E7B86, 0x57A6B2)
        case .gourmand: return Color.dyn(0x83502B, 0xB48155)
        case .spicy: return Color.dyn(0x8E3620, 0xC2654C)
        case .green: return Color.dyn(0x3A6C36, 0x66A55F)
        case .fougere: return Color.dyn(0x445C36, 0x789965)
        case .chypre: return Color.dyn(0x5E446B, 0x9176A1)
        case .aquatic: return Color.dyn(0x215586, 0x5089BB)
        case .leather: return Color.dyn(0x523620, 0x8F684A)
        case .musk: return Color.dyn(0x6F6857, 0xA59E8C)
        }
    }
}
