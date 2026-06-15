import Foundation

/// Free-tier limits and Pro gating. Free: up to 6 loyalty cards + view barcodes.
/// Pro (one-time): unlimited cards, gift-card tracking, premium themes, CSV export.
enum Pro {
    static let priceLabel = "$3.99"

    /// Free users can store up to this many loyalty cards.
    static let freeCardLimit = 6

    /// Whether another loyalty card may be added given the current count + Pro status.
    static func canAddCard(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeCardLimit
    }

    /// Remaining free card slots (nil = unlimited for Pro).
    static func remainingSlots(currentCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeCardLimit - currentCount, 0)
    }
}

/// Reasons the paywall is presented, each with tailored copy.
enum PaywallReason: Identifiable {
    case cardLimit
    case giftCards
    case themes
    case export
    case general

    var id: String {
        switch self {
        case .cardLimit: return "cardLimit"
        case .giftCards: return "giftCards"
        case .themes:    return "themes"
        case .export:    return "export"
        case .general:   return "general"
        }
    }

    var title: String {
        switch self {
        case .cardLimit: return "Your wallet is full"
        case .giftCards: return "Track gift-card balances"
        case .themes:    return "Premium card themes"
        case .export:    return "Export your wallet"
        case .general:   return "Unlock Stash Pro"
        }
    }

    var blurb: String {
        switch self {
        case .cardLimit:
            return "Free Stash holds up to \(Pro.freeCardLimit) loyalty cards. Go Pro to add as many as you carry — there's no limit."
        case .giftCards:
            return "Stash Pro tracks gift-card balances: log spends, watch the remaining ring, and never lose track of a card again."
        case .themes:
            return "Pro unlocks premium card colors and a polished look across your whole wallet."
        case .export:
            return "Pro lets you export every card and balance to a CSV file you fully own."
        case .general:
            return "One simple, one-time unlock. No ads, no account, no subscription — ever."
        }
    }

    var symbol: String {
        switch self {
        case .cardLimit: return "rectangle.stack.badge.plus"
        case .giftCards: return "giftcard.fill"
        case .themes:    return "paintpalette.fill"
        case .export:    return "square.and.arrow.up"
        case .general:   return "crown.fill"
        }
    }
}
