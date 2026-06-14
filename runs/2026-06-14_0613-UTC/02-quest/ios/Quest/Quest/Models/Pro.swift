import SwiftUI

enum Pro {
    /// Free tier game cap. Beyond this, adding requires Quest Pro.
    static let freeGameLimit = 20
    static let price = "$4.99"
    static let productName = "Quest Pro"
}

enum PaywallReason: Identifiable {
    case gameLimit
    case stats
    case export
    case picker

    var id: String {
        switch self {
        case .gameLimit: return "gameLimit"
        case .stats: return "stats"
        case .export: return "export"
        case .picker: return "picker"
        }
    }

    var title: String {
        switch self {
        case .gameLimit: return "Library is full"
        case .stats: return "Unlock full Stats"
        case .export: return "Export your library"
        case .picker: return "Advanced picker filters"
        }
    }

    var message: String {
        switch self {
        case .gameLimit:
            return "The free library holds up to \(Pro.freeGameLimit) games. Upgrade to Quest Pro for an unlimited backlog."
        case .stats:
            return "See platform donuts, genre breakdowns, rating distribution and monthly trends with Quest Pro."
        case .export:
            return "Export your whole library as text to back it up or share, with Quest Pro."
        case .picker:
            return "Filter What-to-Play-Next by platform, genre and max length, and weight by favorites, with Quest Pro."
        }
    }
}
