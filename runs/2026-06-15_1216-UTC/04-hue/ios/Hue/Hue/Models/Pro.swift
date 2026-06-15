import SwiftUI

/// Local, simulated one-time Pro unlock. No StoreKit / network in this build.
enum Pro {
    static let priceLabel = "$3.99"
    static let productName = "Hue Pro"

    /// Free tier may only color these starter pages.
    static let freePageIDs: Set<String> = ["mandala-bloom", "floral-dahlia", "geo-prism", "land-sunset"]

    /// Max saved artworks for free users.
    static let freeArtworkLimit = 6

    static func isPageUnlocked(_ page: ColoringPage, isPro: Bool) -> Bool {
        isPro || !page.isPremium
    }

    static func canCreateArtwork(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeArtworkLimit
    }

    static func canCreateCustomPalette(isPro: Bool) -> Bool { isPro }
    static func exportHasWatermark(isPro: Bool) -> Bool { !isPro }

    static let benefits: [String] = [
        "Every page in the library — all categories, unlocked",
        "Create unlimited custom palettes",
        "Export artwork without the Hue watermark",
        "Save unlimited artworks to your gallery",
        "Support a calm, private, ad-free app"
    ]
}

/// Why the paywall is being shown — tailors the headline copy.
enum PaywallReason: Identifiable {
    case premiumPage(String)
    case customPalette
    case artworkLimit
    case watermarkFreeExport
    case general

    var id: String {
        switch self {
        case .premiumPage(let name): return "page-\(name)"
        case .customPalette: return "palette"
        case .artworkLimit: return "limit"
        case .watermarkFreeExport: return "watermark"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .premiumPage: return "Unlock this page"
        case .customPalette: return "Make it your own"
        case .artworkLimit: return "Room for more art"
        case .watermarkFreeExport: return "Export, watermark-free"
        case .general: return "Unlock all of Hue"
        }
    }

    var subtitle: String {
        switch self {
        case .premiumPage(let name):
            return "\(name) is a Hue Pro page. Unlock it — and every other page — with a single one-time purchase."
        case .customPalette:
            return "Design your own palettes with Hue Pro. Pick exactly the colors that calm you."
        case .artworkLimit:
            return "You've filled your free gallery. Hue Pro lets you keep as many artworks as you like."
        case .watermarkFreeExport:
            return "Share clean, watermark-free images with Hue Pro."
        case .general:
            return "One fair, one-time purchase. No ads, no subscription, no tracking — ever."
        }
    }
}
