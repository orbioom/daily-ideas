import Foundation

/// Local, simulated one-time unlock. Real builds wire this to StoreKit 2.
enum Pro {
    static let priceLabel = "$4.99"
    static let productName = "Stow Pro"

    /// Free tier caps the saved (non-archived) library size.
    static let freeArticleLimit = 15

    /// Reader themes available without Pro.
    static let freeThemes: Set<ReaderTheme> = [.light, .sepia]

    /// Whether saving another article is allowed for the current tier.
    static func canSaveMore(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeArticleLimit
    }

    static func remainingFree(currentCount: Int) -> Int {
        max(0, freeArticleLimit - currentCount)
    }

    /// Reader themes that require Pro.
    static func isThemeLocked(_ theme: ReaderTheme, isPro: Bool) -> Bool {
        if isPro { return false }
        return !freeThemes.contains(theme)
    }

    /// Fonts beyond the base serif require Pro.
    static func isFontLocked(_ font: ReaderFont, isPro: Bool) -> Bool {
        if isPro { return false }
        return font != .serif
    }
}

/// Why the paywall was shown — drives tailored copy.
enum PaywallReason {
    case articleLimit
    case lockedTheme
    case lockedFont
    case highlights
    case tags
    case export
    case general

    var headline: String {
        switch self {
        case .articleLimit: return "Your shelf is full"
        case .lockedTheme:  return "Unlock every reading mood"
        case .lockedFont:   return "Read in your favorite typeface"
        case .highlights:   return "Keep what matters"
        case .tags:         return "Organize without limits"
        case .export:       return "Take your reading anywhere"
        case .general:      return "Make Stow yours, for good"
        }
    }

    var detail: String {
        switch self {
        case .articleLimit:
            return "Free Stow holds \(Pro.freeArticleLimit) articles. Upgrade once to stow as many as you like."
        case .lockedTheme:
            return "Dark and Night reading themes are part of Stow Pro."
        case .lockedFont:
            return "Sans and Rounded reading fonts are part of Stow Pro."
        case .highlights:
            return "Save and revisit highlights from any article with Stow Pro."
        case .tags:
            return "Create unlimited tags to file your library with Stow Pro."
        case .export:
            return "Export articles and highlights as text with Stow Pro."
        case .general:
            return "One purchase. Yours forever. No account, no subscription."
        }
    }
}
