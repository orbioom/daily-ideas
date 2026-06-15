import Foundation

/// One-time Wren Pro unlock (simulated locally via @AppStorage("isPro")).
/// In production this would be backed by StoreKit 2 with a non-consumable product.
enum Pro {
    static let priceLabel = "$4.99"
    static let productName = "Wren Pro"

    // Free-tier limits
    static let freeActiveGoalLimit = 5
    static let freeJourneyLimit = 2

    /// Whether the user can add another active goal given current count + pro state.
    static func canAddGoal(activeCount: Int, isPro: Bool) -> Bool {
        isPro || activeCount < freeActiveGoalLimit
    }

    static let perks: [String] = [
        "Unlimited self-care goals",
        "Every journey & companion cosmetic",
        "Full Insights history & trends",
        "Export your reflections",
        "Support calm, ad-free, one-time pricing"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason {
    case goalLimit
    case proJourney
    case proCosmetic
    case fullInsights
    case exportReflections
    case general

    var title: String {
        switch self {
        case .goalLimit: return "Room to grow"
        case .proJourney: return "A longer journey awaits"
        case .proCosmetic: return "Dress up your Wren"
        case .fullInsights: return "See the whole picture"
        case .exportReflections: return "Keep your reflections"
        case .general: return "Unlock Wren Pro"
        }
    }

    var message: String {
        switch self {
        case .goalLimit:
            return "You're tending the free maximum of \(Pro.freeActiveGoalLimit) goals. Unlock Pro for unlimited self-care goals."
        case .proJourney:
            return "This journey is part of Wren Pro. Unlock every journey your companion can take."
        case .proCosmetic:
            return "This cosmetic is part of Wren Pro. Unlock all accessories and scenes."
        case .fullInsights:
            return "Pro reveals your full history — every trend, balance, and streak over time."
        case .exportReflections:
            return "Export your reflection journal with Wren Pro."
        case .general:
            return "A single, fair, one-time unlock. No subscription, no ads, ever."
        }
    }
}
