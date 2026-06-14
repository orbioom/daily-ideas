import SwiftUI

/// The six learning continents used to group, filter, and tint countries.
enum Continent: String, CaseIterable, Identifiable, Codable, Hashable {
    case africa = "Africa"
    case asia = "Asia"
    case europe = "Europe"
    case northAmerica = "NorthAmerica"
    case southAmerica = "SouthAmerica"
    case oceania = "Oceania"

    var id: String { rawValue }

    /// Human-facing label.
    var title: String {
        switch self {
        case .africa: return "Africa"
        case .asia: return "Asia"
        case .europe: return "Europe"
        case .northAmerica: return "North America"
        case .southAmerica: return "South America"
        case .oceania: return "Oceania"
        }
    }

    var systemImage: String {
        switch self {
        case .africa: return "sun.max"
        case .asia: return "mountain.2"
        case .europe: return "building.columns"
        case .northAmerica: return "leaf"
        case .southAmerica: return "tree"
        case .oceania: return "water.waves"
        }
    }

    var tint: Color {
        switch self {
        case .africa: return Theme.warm
        case .asia: return Theme.sky
        case .europe: return Theme.violet
        case .northAmerica: return Theme.good
        case .southAmerica: return Theme.accent
        case .oceania: return Color.dyn(0x1B9AA6, 0x5FD0DA)
        }
    }

    /// Display order for sectioned lists & dashboards.
    static var displayOrder: [Continent] {
        [.africa, .asia, .europe, .northAmerica, .southAmerica, .oceania]
    }
}
