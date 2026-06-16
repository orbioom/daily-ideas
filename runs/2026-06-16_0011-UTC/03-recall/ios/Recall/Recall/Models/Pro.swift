import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$4.99"
    static let productTitle = "Recall Pro"

    /// Free users may keep up to this many decks. The 4th create attempt shows the paywall.
    static let freeDeckLimit = 3

    /// Study modes available without Pro.
    static let freeModes: [ReviewMode] = [.flip]

    static func modeIsFree(_ mode: ReviewMode) -> Bool { freeModes.contains(mode) }

    static let unlocks: [String] = [
        "Unlimited decks — organize every subject you study",
        "Multiple-choice, type-the-answer, and Cram study modes",
        "The full Stats dashboard: forecast, maturity, retention & streak",
        "Every future study mode and feature drop",
        "A fair, one-time unlock — no subscription, no ads, no account"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case deckLimit
    case studyMode
    case stats
    case general

    var id: String {
        switch self {
        case .deckLimit: return "deckLimit"
        case .studyMode: return "studyMode"
        case .stats: return "stats"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .deckLimit: return "Room for every subject"
        case .studyMode: return "Study your way"
        case .stats: return "See the full picture"
        case .general: return "Unlock Recall Pro"
        }
    }

    var message: String {
        switch self {
        case .deckLimit:
            return "Free covers \(Pro.freeDeckLimit) decks — plenty to start. Recall Pro lifts the cap so every class, language, and exam gets its own deck."
        case .studyMode:
            return "Flip cards are free forever. Multiple-choice, type-the-answer, and Cram drilling are part of Recall Pro."
        case .stats:
            return "Your due forecast, card-maturity mix, retention rate, and study streak live in the full Stats dashboard — part of Recall Pro."
        case .general:
            return "One fair, one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
