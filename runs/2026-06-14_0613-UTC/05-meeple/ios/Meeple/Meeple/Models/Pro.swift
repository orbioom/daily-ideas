import SwiftUI

/// Pro gating + free-tier limits for Meeple.
enum Pro {
    /// Free tier may hold up to this many games before the paywall appears.
    static let freeGameLimit = 15

    static let priceText = "$4.99"
    static let productTitle = "Unlock Meeple Pro"

    static let benefits: [String] = [
        "Unlimited board game collection",
        "Full stats: win rates, H-index, per-player analytics",
        "Advanced Play Picker filters (weight & duration)",
        "Export your collection & plays (CSV / text)"
    ]
}

/// Why the paywall was triggered — drives the headline shown.
enum PaywallReason: Identifiable {
    case gameLimit
    case stats
    case picker
    case export

    var id: String {
        switch self {
        case .gameLimit: return "gameLimit"
        case .stats: return "stats"
        case .picker: return "picker"
        case .export: return "export"
        }
    }

    var headline: String {
        switch self {
        case .gameLimit: return "Your shelf is full"
        case .stats: return "Unlock the full stats lab"
        case .picker: return "Fine-tune your picks"
        case .export: return "Take your data anywhere"
        }
    }

    var detail: String {
        switch self {
        case .gameLimit:
            return "The free tier holds up to \(Pro.freeGameLimit) games. Go Pro for an unlimited collection."
        case .stats:
            return "Win rates, the H-index and per-player analytics are part of Meeple Pro."
        case .picker:
            return "Weight and duration filters in the Play Picker are a Pro feature."
        case .export:
            return "Export your collection and full play history with Meeple Pro."
        }
    }
}
