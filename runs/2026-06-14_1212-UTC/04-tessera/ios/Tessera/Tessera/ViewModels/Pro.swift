import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can store up to this many accounts. Pro is unlimited.
    static let freeAccountLimit = 10

    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"

    /// Whether a new account can be added given the current count and Pro status.
    static func canAddAccount(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeAccountLimit
    }

    /// Remaining free slots (nil when Pro = unlimited).
    static func remainingFreeSlots(currentCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeAccountLimit - currentCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case accountLimit
    case folders
    case export
    case themes

    var id: String {
        switch self {
        case .accountLimit: return "accountLimit"
        case .folders: return "folders"
        case .export: return "export"
        case .themes: return "themes"
        }
    }

    var title: String {
        switch self {
        case .accountLimit: return "You've reached the free limit"
        case .folders: return "Organise with folders"
        case .export: return "Back up your accounts"
        case .themes: return "Unlock appearance themes"
        }
    }

    var blurb: String {
        switch self {
        case .accountLimit:
            return "Free Tessera holds up to \(Pro.freeAccountLimit) accounts. Go Pro for unlimited accounts."
        case .folders:
            return "Group accounts into Work, Personal, and more. Folders are a Tessera Pro feature."
        case .export:
            return "Export every account as an encrypted-at-rest otpauth backup you can re-import anywhere."
        case .themes:
            return "Choose Light, Dark, or System appearance with Tessera Pro."
        }
    }

    var symbol: String {
        switch self {
        case .accountLimit: return "infinity"
        case .folders: return "folder.fill"
        case .export: return "square.and.arrow.up.on.square.fill"
        case .themes: return "paintpalette.fill"
        }
    }
}
