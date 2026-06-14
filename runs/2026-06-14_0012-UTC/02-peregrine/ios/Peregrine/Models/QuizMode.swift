import Foundation

/// The question styles the quiz engine can generate. Each maps to a prompt
/// shape and an answer shape (e.g. flag prompt, country-name answers).
enum QuizMode: String, CaseIterable, Identifiable, Codable, Hashable {
    case flagToCountry
    case countryToCapital
    case capitalToCountry
    case flagToContinent
    case biggerPopulation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flagToCountry: return "Flag → Country"
        case .countryToCapital: return "Country → Capital"
        case .capitalToCountry: return "Capital → Country"
        case .flagToContinent: return "Flag → Continent"
        case .biggerPopulation: return "Bigger Population"
        }
    }

    var shortTitle: String {
        switch self {
        case .flagToCountry: return "Flags"
        case .countryToCapital: return "Capitals"
        case .capitalToCountry: return "Find Country"
        case .flagToContinent: return "Continents"
        case .biggerPopulation: return "Population"
        }
    }

    var blurb: String {
        switch self {
        case .flagToCountry: return "See a flag, name the country."
        case .countryToCapital: return "Match each country to its capital."
        case .capitalToCountry: return "Given a capital, pick the country."
        case .flagToContinent: return "Place each flag on its continent."
        case .biggerPopulation: return "Pick the more populous of two."
        }
    }

    var systemImage: String {
        switch self {
        case .flagToCountry: return "flag.fill"
        case .countryToCapital: return "building.2.fill"
        case .capitalToCountry: return "mappin.and.ellipse"
        case .flagToContinent: return "globe.americas.fill"
        case .biggerPopulation: return "person.3.fill"
        }
    }

    /// Modes available in the free tier (the rest are gated behind Pro).
    static var freeModes: [QuizMode] {
        [.flagToCountry, .countryToCapital]
    }

    func isUnlocked(isPro: Bool) -> Bool {
        isPro || QuizMode.freeModes.contains(self)
    }
}
