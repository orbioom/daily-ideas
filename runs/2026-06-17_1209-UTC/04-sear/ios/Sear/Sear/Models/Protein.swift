import SwiftUI

/// The protein family for a cook and for guide entries.
enum Protein: String, CaseIterable, Identifiable, Codable {
    case beef, pork, poultry, fish, lamb, veg, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .beef: return "Beef"
        case .pork: return "Pork"
        case .poultry: return "Poultry"
        case .fish: return "Fish & Seafood"
        case .lamb: return "Lamb"
        case .veg: return "Vegetables"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .beef: return "fork.knife"
        case .pork: return "fork.knife"
        case .poultry: return "bird"
        case .fish: return "fish"
        case .lamb: return "fork.knife"
        case .veg: return "leaf"
        case .other: return "flame"
        }
    }

    var hue: Color {
        switch self {
        case .beef: return Color(hex: 0xB23A22)
        case .pork: return Color(hex: 0xE48AA0)
        case .poultry: return Color(hex: 0xE8B53C)
        case .fish: return Color(hex: 0x3C8AB0)
        case .lamb: return Color(hex: 0x8A5A3C)
        case .veg: return Color(hex: 0x4FA45A)
        case .other: return Color(hex: 0x8C7B6C)
        }
    }
}
