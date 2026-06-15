import Foundation

/// Free-tier limits and Pro gating. Free: up to 8 holdings + full projections + calendar.
/// Pro (one-time): unlimited holdings, the DRIP projector, CSV export, multiple accounts,
/// and the hide-balances privacy mode.
enum Pro {
    static let priceLabel = "$6.99"

    /// Maximum holdings on the free tier.
    static let freeHoldingLimit = 8

    /// Whether the user can add another holding given current count + Pro status.
    static func canAddHolding(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeHoldingLimit
    }

    /// Remaining free slots (nil = unlimited for Pro).
    static func remainingSlots(currentCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeHoldingLimit - currentCount, 0)
    }
}

/// Reasons the paywall is presented — drives its headline, blurb, and icon.
enum PaywallReason: Identifiable {
    case holdingLimit
    case drip
    case export
    case accounts
    case privacy
    case general

    var id: String {
        switch self {
        case .holdingLimit: return "holdingLimit"
        case .drip: return "drip"
        case .export: return "export"
        case .accounts: return "accounts"
        case .privacy: return "privacy"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .holdingLimit: return "You've filled your free portfolio"
        case .drip: return "Unlock the DRIP Projector"
        case .export: return "Export your portfolio"
        case .accounts: return "Track multiple accounts"
        case .privacy: return "Hide your balances"
        case .general: return "Unlock Yield Pro"
        }
    }

    var blurb: String {
        switch self {
        case .holdingLimit:
            return "Free Yield tracks up to \(Pro.freeHoldingLimit) holdings. Go Pro for an unlimited portfolio — every position, one private place."
        case .drip:
            return "Model years of dividend reinvestment and DPS growth with the interactive DRIP Projector. Yield Pro unlocks it."
        case .export:
            return "Export your holdings to CSV for your own spreadsheets and backups. Part of Yield Pro."
        case .accounts:
            return "Tag holdings by account — taxable, IRA, ISA — and see income per account. Yield Pro unlocks multiple accounts."
        case .privacy:
            return "Glance at your portfolio in public without showing the numbers. Hide-balances mode is part of Yield Pro."
        case .general:
            return "One private, offline dividend tracker — yours for a single payment, no subscription, no brokerage login."
        }
    }

    var symbol: String {
        switch self {
        case .holdingLimit: return "tray.full.fill"
        case .drip: return "arrow.triangle.2.circlepath"
        case .export: return "square.and.arrow.up"
        case .accounts: return "folder.fill.badge.person.crop"
        case .privacy: return "eye.slash.fill"
        case .general: return "crown.fill"
        }
    }
}
