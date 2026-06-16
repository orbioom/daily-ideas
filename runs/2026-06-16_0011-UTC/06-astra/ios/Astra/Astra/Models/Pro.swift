import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$4.99"
    static let productTitle = "Astra Pro"

    /// Free tier: a single saved chart.
    static let freeProfileLimit = 1

    static let unlocks: [String] = [
        "Unlimited birth charts — family, friends, and your own past relocations",
        "The full natal wheel, drawn to the exact degree with every aspect line",
        "Every placement, house, and aspect with grounded interpretations",
        "Compatibility (synastry) — compare any two charts with a real score",
        "Multi-day transit outlook so you can see what's coming, calmly",
        "Support a private, ad-free app — your chart never leaves your device"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case moreProfiles
    case fullWheel
    case allPlacements
    case compatibility
    case transitOutlook
    case general

    var id: String {
        switch self {
        case .moreProfiles: return "moreProfiles"
        case .fullWheel: return "fullWheel"
        case .allPlacements: return "allPlacements"
        case .compatibility: return "compatibility"
        case .transitOutlook: return "transitOutlook"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .moreProfiles: return "Add more charts"
        case .fullWheel: return "See the full wheel"
        case .allPlacements: return "Unlock every placement"
        case .compatibility: return "Compare two charts"
        case .transitOutlook: return "See the days ahead"
        case .general: return "Unlock Astra Pro"
        }
    }

    var message: String {
        switch self {
        case .moreProfiles:
            return "The free tier keeps one chart. Astra Pro lets you save charts for everyone you care about — and your own relocations — all private on your device."
        case .fullWheel:
            return "The natal wheel — every planet at its exact degree, with the aspect lines that shape your chart — is part of Astra Pro."
        case .allPlacements:
            return "Free shows your Sun, Moon, and Rising. Pro reveals every planet, house, and aspect with a grounded interpretation for each."
        case .compatibility:
            return "Synastry compares two charts cross-aspect by cross-aspect for a real compatibility score. It's part of Astra Pro."
        case .transitOutlook:
            return "Pro extends today's reading into a calm multi-day outlook, so the sky never surprises you."
        case .general:
            return "One fair, one-time unlock — no subscription, no ads, no account. Your chart never leaves your device."
        }
    }
}
