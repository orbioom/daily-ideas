import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$4.99"
    static let productTitle = "Tonus Pro"

    /// Free users get the beginner-level built-in programs only.
    static let freeMaxLevel = 1
    /// Free users see only the last 7 days of history.
    static let freeHistoryDays = 7

    static let unlocks: [String] = [
        "Every training program — intermediate, advanced & endurance",
        "Build your own custom programs, tuned to you",
        "Full history and lifetime insights — not just the last 7 days",
        "Daily reminders to keep your streak alive",
        "All future programs, free"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case lockedProgram
    case customBuilder
    case fullHistory
    case reminders
    case general

    var id: String {
        switch self {
        case .lockedProgram: return "lockedProgram"
        case .customBuilder: return "customBuilder"
        case .fullHistory: return "fullHistory"
        case .reminders: return "reminders"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .lockedProgram: return "Unlock this program"
        case .customBuilder: return "Build your own program"
        case .fullHistory: return "See your full history"
        case .reminders: return "Stay on track"
        case .general: return "Unlock Tonus Pro"
        }
    }

    var message: String {
        switch self {
        case .lockedProgram:
            return "This program is part of Tonus Pro. Unlock every program — from gentle foundations to long endurance holds."
        case .customBuilder:
            return "Design programs around your own routine: set the contract, hold, relax, reps and sets exactly how your body needs them."
        case .fullHistory:
            return "Free shows the last 7 days. Unlock lifetime insights — every streak, every minute, your full trend."
        case .reminders:
            return "A gentle daily nudge at a time you choose keeps the habit — and your streak — going."
        case .general:
            return "One fair one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
