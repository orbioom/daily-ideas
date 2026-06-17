import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$4.99"
    static let productTitle = "Arcana Pro"

    /// Free tier keeps up to this many saved journal readings; daily draws are always unlimited.
    static let freeReadingLimit = 15

    static let unlocks: [String] = [
        "The Celtic Cross — the ten-card masterwork for deep, layered readings",
        "Every advanced spread: Relationship and Decision layouts",
        "Unlimited journal entries — keep a lifetime of readings",
        "Extra deck-back themes to make Arcana your own",
        "Export any reading as text to share or keep",
        "Support a private, ad-free app — your readings never leave your device"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case advancedSpread(String)
    case journalLimit
    case deckThemes
    case export
    case general

    var id: String {
        switch self {
        case .advancedSpread(let s): return "spread-\(s)"
        case .journalLimit: return "journalLimit"
        case .deckThemes: return "deckThemes"
        case .export: return "export"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .advancedSpread: return "Unlock this spread"
        case .journalLimit: return "Keep every reading"
        case .deckThemes: return "More deck themes"
        case .export: return "Export your reading"
        case .general: return "Unlock Arcana Pro"
        }
    }

    var message: String {
        switch self {
        case .advancedSpread(let name):
            return "The \(name) is part of Arcana Pro, alongside every advanced spread and the full Celtic Cross."
        case .journalLimit:
            return "The free journal keeps your most recent \(Pro.freeReadingLimit) readings. Arcana Pro keeps them all, for a lifetime of reflection."
        case .deckThemes:
            return "Extra deck-back themes come with Arcana Pro — make the deck feel like yours."
        case .export:
            return "Exporting a reading as shareable text is part of Arcana Pro."
        case .general:
            return "One fair, one-time unlock — no subscription, no ads, no account. Your readings never leave your device."
        }
    }
}
