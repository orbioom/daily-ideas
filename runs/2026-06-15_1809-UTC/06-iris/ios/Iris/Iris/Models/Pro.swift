import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$3.99"
    static let productTitle = "Iris Pro"

    static let unlocks: [String] = [
        "Every guided eye-exercise routine — Relax, Strengthen, Focus & Dry-Eye",
        "Your full stats history — streaks, trends and weekly summaries",
        "All comfort tools — Amsler grid, focus-flexibility drill & blink trainer",
        "Unlimited 20-20-20 breaks tracked toward your daily goal",
        "Calm, ad-free, private — everything stays on your device"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case routineLocked
    case fullHistory
    case toolLocked
    case general

    var id: String {
        switch self {
        case .routineLocked: return "routine"
        case .fullHistory: return "history"
        case .toolLocked: return "tool"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .routineLocked: return "Unlock every routine"
        case .fullHistory: return "See your full history"
        case .toolLocked: return "Unlock all comfort tools"
        case .general: return "Unlock Iris Pro"
        }
    }

    var message: String {
        switch self {
        case .routineLocked:
            return "The 20-20-20 break and one starter routine are always free. Iris Pro opens every guided routine across Relax, Strengthen, Focus and Dry-Eye."
        case .fullHistory:
            return "Free shows this week. Iris Pro reveals your full streak history, exercise-minute trends and weekly summaries so you can see your progress over time."
        case .toolLocked:
            return "The Amsler self-check is free. Iris Pro adds the focus-flexibility drill and the blink-rate trainer, plus deeper guidance."
        case .general:
            return "A single, fair one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
