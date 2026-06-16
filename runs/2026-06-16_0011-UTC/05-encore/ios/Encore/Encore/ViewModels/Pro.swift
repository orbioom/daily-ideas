import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$3.99"
    static let productTitle = "Encore Pro"

    /// Free fans may log up to this many shows; the next one prompts the paywall.
    static let freeShowLimit = 20
    /// Free fans may remember up to this many songs per setlist.
    static let freeSetlistLimit = 5

    /// Whether another show can be added for free given the current attended+wishlist count.
    static func canAddShow(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeShowLimit
    }

    /// Whether another setlist song can be added for free.
    static func canAddSong(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeSetlistLimit
    }

    static let unlocks: [String] = [
        "Log unlimited shows — your whole concert history, no cap",
        "Full Stats: every chart, top artists, venues, genres and spend",
        "Track complete setlists, beyond the first \(freeSetlistLimit) songs",
        "Your Concert Wrapped share card to post your year in live music",
        "Export your entire log to CSV",
        "Support a calm, ad-free, one-time-purchase app"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case showLimit
    case setlistLimit
    case fullStats
    case wrapped
    case export
    case general

    var id: String {
        switch self {
        case .showLimit: return "showLimit"
        case .setlistLimit: return "setlistLimit"
        case .fullStats: return "fullStats"
        case .wrapped: return "wrapped"
        case .export: return "export"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .showLimit: return "Log every show"
        case .setlistLimit: return "Remember the whole setlist"
        case .fullStats: return "Unlock your full Stats"
        case .wrapped: return "Share your Concert Wrapped"
        case .export: return "Export your concert log"
        case .general: return "Unlock Encore Pro"
        }
    }

    var message: String {
        switch self {
        case .showLimit:
            return "You've logged \(Pro.freeShowLimit) shows on the free tier — a great run. Encore Pro removes the cap so your entire gig history lives in one place."
        case .setlistLimit:
            return "Free remembers the first \(Pro.freeSetlistLimit) songs of a setlist. Encore Pro tracks the full set, encores and all."
        case .fullStats:
            return "Shows-per-year, top artists and venues, your genre mix, and spend over time are part of Encore Pro."
        case .wrapped:
            return "Your Concert Wrapped sums up your year in live music as a shareable card. It's part of Encore Pro."
        case .export:
            return "Export your whole log to CSV — a clean backup you own. It's part of Encore Pro."
        case .general:
            return "One fair, one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
