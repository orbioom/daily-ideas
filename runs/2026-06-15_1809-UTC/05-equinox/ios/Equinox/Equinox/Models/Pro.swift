import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$4.99"
    static let productTitle = "Equinox Pro"

    /// Free users can browse history this many days back; Pro is unlimited.
    static let freeHistoryDays = 30

    static let unlocks: [String] = [
        "Full insights — domain trends, correlations, and the stage timeline",
        "Unlimited history beyond the last 30 days",
        "Doctor-report export — a clean summary to share with your clinician",
        "The complete Learn library — every evidence-based article",
        "One fair, one-time unlock — no subscription, no ads, no account"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case insights
    case history
    case doctorReport
    case learnArticle
    case general

    var id: String {
        switch self {
        case .insights: return "insights"
        case .history: return "history"
        case .doctorReport: return "doctorReport"
        case .learnArticle: return "learnArticle"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .insights: return "See your full picture"
        case .history: return "Look further back"
        case .doctorReport: return "Prepare for your appointment"
        case .learnArticle: return "Read the full library"
        case .general: return "Unlock Equinox Pro"
        }
    }

    var message: String {
        switch self {
        case .insights:
            return "You can track every day for free. Pro adds domain severity trends, sleep-and-hot-flash correlations, and your personal stage timeline."
        case .history:
            return "Free shows the last 30 days. Pro keeps your full history so you can see months of patterns at a glance."
        case .doctorReport:
            return "Generate a clear, shareable summary — date range, average hot flashes, top symptoms, and cycle changes — to bring to your clinician."
        case .learnArticle:
            return "Unlock every evidence-based article on hot flashes, sleep, mood, HRT basics, bone and heart health, and lifestyle."
        case .general:
            return "A single, fair one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
