import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$4.99"
    static let productTitle = "Facet Pro"

    /// Free users may keep this many profiles total (their own + comparisons).
    static let freeProfileLimit = 1

    static let unlocks: [String] = [
        "Your full archetype report — strengths, growth areas, careers & relationships",
        "Compatibility between any two profiles",
        "Add unlimited profiles for friends & family",
        "Export and share your beautiful result card",
        "Full detail for all 16 archetypes in Explore"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason {
    case fullReport
    case compatibility
    case addProfile
    case shareCard
    case archetypeLibrary
    case general

    var title: String {
        switch self {
        case .fullReport: return "Unlock your full report"
        case .compatibility: return "See your compatibility"
        case .addProfile: return "Add more profiles"
        case .shareCard: return "Share your result card"
        case .archetypeLibrary: return "Explore every archetype"
        case .general: return "Unlock Facet Pro"
        }
    }

    var message: String {
        switch self {
        case .fullReport:
            return "You've got your type and trait bars. Go deeper with your strengths, growth areas, ideal careers, and how you show up in relationships."
        case .compatibility:
            return "Compare any two profiles to see where you align, where you complement each other, and how to bridge the gaps."
        case .addProfile:
            return "Free includes one profile. Add your partner, friends, and family to compare and explore together."
        case .shareCard:
            return "Export a beautiful, shareable card of your result to send to friends."
        case .archetypeLibrary:
            return "Read the full, rich profile for every one of the 16 archetypes."
        case .general:
            return "A single, fair one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
