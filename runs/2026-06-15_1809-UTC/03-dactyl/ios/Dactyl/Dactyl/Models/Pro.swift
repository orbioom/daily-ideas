import Foundation

/// Local, simulated one-time Pro unlock. (StoreKit 2 would wire in here for production.)
enum Pro {
    static let priceLabel = "$3.99"
    static let productTitle = "Dactyl Pro"

    static let unlocks: [String] = [
        "Every lesson tier — top row, numbers, punctuation, capitals, words & sentences",
        "All test modes — 15s, 60s and word-count sprints",
        "Custom drills — type your own text and practice it",
        "Full stats — WPM & accuracy trends over time",
        "The per-key error heatmap — see exactly which keys trip you up"
    ]
}

/// Why the paywall is being shown — drives tailored copy.
enum PaywallReason: Identifiable {
    case lockedLesson
    case testMode
    case customDrill
    case fullStats
    case keyHeatmap
    case general

    var id: String {
        switch self {
        case .lockedLesson: return "lockedLesson"
        case .testMode: return "testMode"
        case .customDrill: return "customDrill"
        case .fullStats: return "fullStats"
        case .keyHeatmap: return "keyHeatmap"
        case .general: return "general"
        }
    }

    var title: String {
        switch self {
        case .lockedLesson: return "Unlock every lesson"
        case .testMode: return "Unlock all test modes"
        case .customDrill: return "Practice your own text"
        case .fullStats: return "See your full progress"
        case .keyHeatmap: return "Unlock the key heatmap"
        case .general: return "Unlock Dactyl Pro"
        }
    }

    var message: String {
        switch self {
        case .lockedLesson:
            return "The Home Row lessons are free. Go Pro to climb the full curriculum — top row, numbers, punctuation, capitals, common words and sentences."
        case .testMode:
            return "The 30-second test is free. Pro adds 15s and 60s sprints plus word-count modes so you can benchmark however you like."
        case .customDrill:
            return "Paste any text — a paragraph, some code, a tongue-twister — and drill it with full live stats."
        case .fullStats:
            return "Track your WPM and accuracy over weeks and watch the trend line climb."
        case .keyHeatmap:
            return "Dactyl's signature insight: a keyboard colored by your real error rate, so you know exactly which keys to practice."
        case .general:
            return "A single fair one-time unlock — no subscription, no ads, no account. Everything stays private on your device."
        }
    }
}
