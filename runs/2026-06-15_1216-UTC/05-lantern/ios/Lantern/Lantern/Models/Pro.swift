import Foundation

/// Local, simulated one-time "Lantern Pro" unlock. (Production wires StoreKit 2;
/// here we flip `@AppStorage("isPro")`.) No ads, no subscription, no account.
enum Pro {
    static let priceLabel = "$3.99"
    static let productName = "Lantern Pro"

    // Free-tier limits.
    static let freeHintsPerGame = 3
    static let freeShufflesPerGame = 1

    /// Layouts available on the free tier.
    static let freeLayouts: [LayoutKind] = LayoutKind.allCases.filter { $0.isFreeTier }

    static func isLayoutUnlocked(_ layout: LayoutKind, isPro: Bool) -> Bool {
        isPro || layout.isFreeTier
    }

    static func hintLimit(isPro: Bool) -> Int? {
        isPro ? nil : freeHintsPerGame      // nil = unlimited
    }
    static func shuffleLimit(isPro: Bool) -> Int? {
        isPro ? nil : freeShufflesPerGame
    }

    /// What Pro unlocks, for display on the paywall.
    static let perks: [String] = [
        "All board layouts — Pyramid, Fortress, and more",
        "Unlimited hints and shuffles",
        "The full Daily Challenge archive",
        "Premium tile themes and back colors",
        "Support a calm, ad-free game"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case lockedLayout(LayoutKind)
    case outOfHints
    case outOfShuffles
    case dailyArchive
    case tileThemes
    case general

    var id: String {
        switch self {
        case .lockedLayout(let l): return "layout-\(l.rawValue)"
        case .outOfHints: return "hints"
        case .outOfShuffles: return "shuffles"
        case .dailyArchive: return "archive"
        case .tileThemes: return "themes"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .lockedLayout: return "Unlock every layout"
        case .outOfHints: return "Out of hints"
        case .outOfShuffles: return "Out of shuffles"
        case .dailyArchive: return "Open the Daily archive"
        case .tileThemes: return "Make it yours"
        case .general: return "Lantern Pro"
        }
    }

    var message: String {
        switch self {
        case .lockedLayout(let l):
            return "\(l.displayName) is part of Lantern Pro. Unlock it once and keep every layout forever."
        case .outOfHints:
            return "You've used your free hints for this game. Lantern Pro gives you unlimited hints, every game."
        case .outOfShuffles:
            return "Free games include one shuffle. Lantern Pro unlocks unlimited shuffles to keep boards moving."
        case .dailyArchive:
            return "Replay any past Daily Challenge with Lantern Pro. The free tier plays today's puzzle."
        case .tileThemes:
            return "Premium tile faces and lantern-lit back colors are part of Lantern Pro."
        case .general:
            return "One calm, ad-free game. Unlock everything once — no subscription, no account."
        }
    }
}
