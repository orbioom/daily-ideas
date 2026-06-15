import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$5.99"
    static let productTitle = "Felt Pro"

    /// Free users may log up to this many sessions total.
    static let freeSessionLimit = 25

    static let unlocks: [String] = [
        "Log unlimited sessions — no cap",
        "Full analytics breakdowns by stake, game, location & month",
        "The Bankroll module — deposits, withdrawals & ROI",
        "Bankroll-management guidance for your stakes",
        "Export your full session history to CSV"
    ]

    /// Whether a free user may add another session given their current count.
    static func canAddSession(isPro: Bool, currentCount: Int) -> Bool {
        isPro || currentCount < freeSessionLimit
    }

    /// Sessions remaining before the free cap (nil when Pro / unlimited).
    static func sessionsRemaining(isPro: Bool, currentCount: Int) -> Int? {
        guard !isPro else { return nil }
        return max(0, freeSessionLimit - currentCount)
    }
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case sessionLimit
    case analytics
    case bankroll
    case csvExport
    case general

    var id: String {
        switch self {
        case .sessionLimit: return "sessionLimit"
        case .analytics: return "analytics"
        case .bankroll: return "bankroll"
        case .csvExport: return "csvExport"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .sessionLimit: return "Keep logging sessions"
        case .analytics: return "Unlock full analytics"
        case .bankroll: return "Open the Bankroll module"
        case .csvExport: return "Export to CSV"
        case .general: return "Unlock Felt Pro"
        }
    }

    var message: String {
        switch self {
        case .sessionLimit:
            return "You've reached the free limit of \(Pro.freeSessionLimit) sessions. Unlock Felt Pro to log unlimited sessions and keep your whole history in one place."
        case .analytics:
            return "Go deeper with full breakdowns by stake, game type, location, and month — plus profit-over-time and win-rate detail."
        case .bankroll:
            return "Track deposits and withdrawals, watch your bankroll over time, and see ROI and management guidance for your stakes."
        case .csvExport:
            return "Export your complete session history to CSV for spreadsheets, taxes, or your own deeper analysis."
        case .general:
            return "A single, fair one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
