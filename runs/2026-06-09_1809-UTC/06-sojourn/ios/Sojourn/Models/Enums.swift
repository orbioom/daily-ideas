import Foundation
import SwiftUI

/// The six inhabited continents Sojourn tracks. Antarctica is intentionally
/// excluded from the dataset so "% of the world" stays intuitive.
enum Continent: String, CaseIterable, Identifiable, Codable {
    case africa, asia, europe, northAmerica, southAmerica, oceania

    var id: String { rawValue }

    var label: String {
        switch self {
        case .africa: return "Africa"
        case .asia: return "Asia"
        case .europe: return "Europe"
        case .northAmerica: return "North America"
        case .southAmerica: return "South America"
        case .oceania: return "Oceania"
        }
    }

    var symbol: String {
        switch self {
        case .africa: return "globe.europe.africa.fill"
        case .asia: return "globe.asia.australia.fill"
        case .europe: return "globe.europe.africa.fill"
        case .northAmerica: return "globe.americas.fill"
        case .southAmerica: return "globe.americas.fill"
        case .oceania: return "globe.asia.australia.fill"
        }
    }

    var tint: Color {
        switch self {
        case .africa: return Brand.warn
        case .asia: return Brand.danger
        case .europe: return Brand.info
        case .northAmerica: return Brand.magic
        case .southAmerica: return Brand.live
        case .oceania: return Brand.text2
        }
    }

    /// Total countries in this continent, derived from the static dataset.
    var totalCountries: Int {
        CountryData.all.lazy.filter { $0.continent == self }.count
    }
}

/// How the user relates to a country they've marked.
enum VisitStatus: String, CaseIterable, Identifiable, Codable {
    case visited, lived, transit, wishlist

    var id: String { rawValue }

    var label: String {
        switch self {
        case .visited: return "Visited"
        case .lived: return "Lived"
        case .transit: return "Transit"
        case .wishlist: return "Wishlist"
        }
    }

    var symbol: String {
        switch self {
        case .visited: return "checkmark.seal.fill"
        case .lived: return "house.fill"
        case .transit: return "airplane"
        case .wishlist: return "heart.fill"
        }
    }

    var tint: Color {
        switch self {
        case .visited: return Brand.magic
        case .lived: return Brand.info
        case .transit: return Brand.warn
        case .wishlist: return Brand.danger
        }
    }

    /// Whether this status counts a country as "been there" for world progress.
    /// Transit is conditional on a user preference handled by the engine.
    var isGrounded: Bool {
        self == .visited || self == .lived
    }
}
