import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can track up to this many titles. Pro is unlimited.
    static let freeTitleLimit = 20

    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"

    /// Whether a new title can be tracked given the current count and Pro status.
    static func canAddTitle(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeTitleLimit
    }

    /// Remaining free title slots (nil when Pro = unlimited).
    static func remainingFreeSlots(currentCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeTitleLimit - currentCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case titleLimit
    case stats
    case export

    var id: String {
        switch self {
        case .titleLimit: return "titleLimit"
        case .stats: return "stats"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .titleLimit: return "Your free shelf is full"
        case .stats: return "Unlock your full Taste Stats"
        case .export: return "Export your library"
        }
    }

    var blurb: String {
        switch self {
        case .titleLimit:
            return "Free Senpai tracks up to \(Pro.freeTitleLimit) titles. Go Pro for an unlimited library."
        case .stats:
            return "See your status donut, score histogram, top genres, completions over time, and time-spent totals."
        case .export:
            return "Copy or share your whole library as clean text or CSV."
        }
    }

    var symbol: String {
        switch self {
        case .titleLimit: return "infinity"
        case .stats: return "chart.pie.fill"
        case .export: return "square.and.arrow.up"
        }
    }
}
