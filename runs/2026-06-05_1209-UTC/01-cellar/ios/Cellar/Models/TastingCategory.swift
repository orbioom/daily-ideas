import SwiftUI

/// The kind of thing a bottle (or bag, or tin) holds. Each category carries its own
/// SF Symbol, accent tint, and a curated flavor lexicon used by the tasting forms.
enum TastingCategory: String, CaseIterable, Identifiable, Codable {
    case coffee
    case wine
    case whisky
    case tea
    case beer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coffee: return "Coffee"
        case .wine:   return "Wine"
        case .whisky: return "Whisky"
        case .tea:    return "Tea"
        case .beer:   return "Beer"
        }
    }

    var symbol: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .wine:   return "wineglass.fill"
        case .whisky: return "drop.fill"
        case .tea:    return "leaf.fill"
        case .beer:   return "mug.fill"
        }
    }

    /// A calm tint used for the category badge and the bottle's default chip color.
    var tintHex: UInt32 {
        switch self {
        case .coffee: return 0x9C6B4A
        case .wine:   return 0x8A4A63
        case .whisky: return 0xB6843E
        case .tea:    return 0x5E8A6A
        case .beer:   return 0xB59433
        }
    }

    var tint: Color { Color(hex: tintHex) }

    /// What the "origin" field means for this category, shown as a field label.
    var originLabel: String {
        switch self {
        case .coffee: return "Origin / Roaster"
        case .wine:   return "Region"
        case .whisky: return "Distillery / Region"
        case .tea:    return "Garden / Region"
        case .beer:   return "Brewery"
        }
    }

    /// What the "year" field means.
    var yearLabel: String {
        switch self {
        case .wine:   return "Vintage"
        case .whisky: return "Age / Year"
        default:      return "Year"
        }
    }

    /// A curated lexicon of tasting descriptors for the flavor picker.
    var flavorLexicon: [String] {
        switch self {
        case .coffee:
            return ["Berry", "Citrus", "Stone Fruit", "Floral", "Chocolate",
                    "Caramel", "Nutty", "Honey", "Spice", "Earthy", "Winey", "Bright"]
        case .wine:
            return ["Cherry", "Blackcurrant", "Plum", "Vanilla", "Oak", "Tobacco",
                    "Leather", "Pepper", "Floral", "Citrus", "Mineral", "Tannic"]
        case .whisky:
            return ["Peat", "Smoke", "Vanilla", "Honey", "Sherry", "Oak",
                    "Dried Fruit", "Spice", "Toffee", "Citrus", "Brine", "Malt"]
        case .tea:
            return ["Floral", "Grassy", "Vegetal", "Honey", "Stone Fruit", "Malty",
                    "Roasted", "Nutty", "Citrus", "Mineral", "Sweet", "Astringent"]
        case .beer:
            return ["Hoppy", "Citrus", "Pine", "Malty", "Caramel", "Roasted",
                    "Coffee", "Chocolate", "Fruity", "Yeasty", "Bitter", "Crisp"]
        }
    }
}
