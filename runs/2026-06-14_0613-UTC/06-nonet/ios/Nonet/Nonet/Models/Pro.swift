import SwiftUI

/// Pro entitlement. One-time unlock (demo; no real StoreKit transaction here).
enum Pro {
    /// Stored flag for the one-time "Unlock Nonet Pro" purchase.
    static let storageKey = "isPro"
    static let price = "$2.99"

    static var isUnlocked: Bool {
        UserDefaults.standard.bool(forKey: storageKey)
    }
}

/// Why a paywall was shown — drives copy in `PaywallView`.
/// Identifiable so it can drive `.sheet(item:)`.
enum PaywallReason: Identifiable {
    case difficulty(Difficulty)
    case hints
    case themes
    case stats

    var id: String {
        switch self {
        case .difficulty(let d): return "difficulty-\(d.rawValue)"
        case .hints: return "hints"
        case .themes: return "themes"
        case .stats: return "stats"
        }
    }

    var title: String {
        switch self {
        case .difficulty: return "Unlock Hard & Expert"
        case .hints: return "Unlimited Hints"
        case .themes: return "Extra Board Themes"
        case .stats: return "Full Stats History"
        }
    }

    var blurb: String {
        switch self {
        case .difficulty(let d):
            return "\(d.title) puzzles use \(d.subtitle.lowercased()). Unlock Nonet Pro to play Hard and Expert, as many as you like."
        case .hints:
            return "You've used your free hints for this game. Nonet Pro gives you unlimited logical hints with full technique explanations."
        case .themes:
            return "Nonet Pro adds extra board themes to make the paper-and-ink feel your own."
        case .stats:
            return "Nonet Pro keeps your full history and unlocks deeper stats across every difficulty."
        }
    }
}
