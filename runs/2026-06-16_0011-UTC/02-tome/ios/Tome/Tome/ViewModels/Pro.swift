import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$3.99"
    static let productTitle = "Tome Pro"

    /// Free readers may track up to this many books; the next one triggers the paywall.
    static let freeBookLimit = 30

    static let unlocks: [String] = [
        "Track an unlimited library — no 30-book cap",
        "Full reading stats: genre breakdown, pace & projections",
        "Custom tags and moods to organize your shelves your way",
        "Export your whole library to CSV anytime",
        "Support a calm, private, ad-free reading tracker"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case bookLimit
    case stats
    case tags
    case export
    case general

    var id: String {
        switch self {
        case .bookLimit: return "bookLimit"
        case .stats: return "stats"
        case .tags: return "tags"
        case .export: return "export"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .bookLimit: return "Your shelves are filling up"
        case .stats: return "Unlock your full reading stats"
        case .tags: return "Organize with custom tags"
        case .export: return "Export your library"
        case .general: return "Unlock Tome Pro"
        }
    }

    var message: String {
        switch self {
        case .bookLimit:
            return "You've reached the \(Pro.freeBookLimit)-book free limit. Tome Pro removes the cap so your whole reading life lives in one place."
        case .stats:
            return "Genre breakdowns, reading pace, and finish-date projections are part of Tome Pro — see exactly how you read."
        case .tags:
            return "Create your own moods and genres to shelve books the way your brain actually works. That's a Pro feature."
        case .export:
            return "Export every book and reading session to a CSV you own. One-time unlock, no subscription."
        case .general:
            return "One fair, one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
