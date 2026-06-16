import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$3.99"
    static let productTitle = "Reel Pro"

    /// Free members may track up to this many titles. The 41st triggers the paywall.
    static let freeTitleLimit = 40

    /// Returns true when adding one more title is allowed for this tier.
    static func canAddTitle(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeTitleLimit
    }

    static let unlocks: [String] = [
        "Track an unlimited library — no 40-title cap",
        "Full Stats: genre donut, by-decade history, and ratings deep-dive",
        "Export your whole diary & library to CSV",
        "Diary archive: keep and browse every watch you ever log",
        "Support a calm, ad-free, one-time-purchase app"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case titleLimit
    case fullStats
    case export
    case archive
    case general

    var id: String {
        switch self {
        case .titleLimit: return "titleLimit"
        case .fullStats: return "fullStats"
        case .export: return "export"
        case .archive: return "archive"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .titleLimit: return "Unlock an unlimited library"
        case .fullStats: return "See your full viewing stats"
        case .export: return "Export your diary"
        case .archive: return "Keep your whole diary"
        case .general: return "Unlock Reel Pro"
        }
    }

    var message: String {
        switch self {
        case .titleLimit:
            return "You've reached the free 40-title limit. Reel Pro lifts the cap so you can track every film and show you watch — for one fair, one-time price."
        case .fullStats:
            return "Your genre donut, by-decade history, and ratings deep-dive are part of Reel Pro. Unlock them to see the full shape of your taste."
        case .export:
            return "Export your entire library and diary to a CSV you own. CSV export is part of Reel Pro."
        case .archive:
            return "Reel Pro keeps every diary entry you ever log, so your whole watching history stays with you."
        case .general:
            return "One fair, one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
