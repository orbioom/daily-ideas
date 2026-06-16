import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$2.99"
    static let productTitle = "Limn Pro"

    /// Free players get a mistake budget per puzzle in assist mode; Pro removes the cap.
    static let freeMistakeCap = 5

    static let unlocks: [String] = [
        "The 15×15 “Masterpieces” pack — the deepest, most rewarding pictures",
        "Every extra puzzle pack, including future drops",
        "Replay any past day from the Daily archive",
        "No mistake cap — solve at your own pace, your way",
        "Support a calm, ad-free, one-time-purchase game"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case lockedPack
    case dailyArchive
    case mistakeCap
    case general

    var id: String {
        switch self {
        case .lockedPack: return "lockedPack"
        case .dailyArchive: return "dailyArchive"
        case .mistakeCap: return "mistakeCap"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .lockedPack: return "Unlock every pack"
        case .dailyArchive: return "Replay the Daily archive"
        case .mistakeCap: return "Solve without limits"
        case .general: return "Unlock Limn Pro"
        }
    }

    var message: String {
        switch self {
        case .lockedPack:
            return "This pack — including the 15×15 Masterpieces — is part of Limn Pro. Bigger grids, richer pictures, hours more puzzles."
        case .dailyArchive:
            return "A fresh seeded puzzle arrives every day. Pro lets you go back and solve any day you missed."
        case .mistakeCap:
            return "You've reached the free mistake cap for this puzzle. Limn Pro removes the cap so a slip never ends a solve."
        case .general:
            return "One fair, one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
