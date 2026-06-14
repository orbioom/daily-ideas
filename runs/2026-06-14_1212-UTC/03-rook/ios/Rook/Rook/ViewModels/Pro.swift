import Foundation

/// Free-tier limits and Pro gating logic. Core play and the daily puzzle are never gated.
enum Pro {
    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"

    /// Whether a puzzle is playable for free (daily + starter set).
    static func canPlayPuzzle(id: Int, isPro: Bool, date: Date = Date()) -> Bool {
        if isPro { return true }
        return PuzzleBank.freeAvailableIDs(for: date).contains(id)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case puzzleLibrary
    case premiumBoard
    case stats

    var id: String {
        switch self {
        case .puzzleLibrary: return "puzzleLibrary"
        case .premiumBoard: return "premiumBoard"
        case .stats: return "stats"
        }
    }

    var title: String {
        switch self {
        case .puzzleLibrary: return "Unlock the full puzzle library"
        case .premiumBoard: return "Premium boards & pieces"
        case .stats: return "Unlock your full stats"
        }
    }

    var blurb: String {
        switch self {
        case .puzzleLibrary:
            return "Free Rook gives you the daily puzzle plus a starter set. Rook Pro opens every tactic in the library."
        case .premiumBoard:
            return "Slate Blue and Newsprint Gray boards are part of Rook Pro, alongside the full tactics library."
        case .stats:
            return "See your full results history, by-theme accuracy, and streak charts."
        }
    }

    var symbol: String {
        switch self {
        case .puzzleLibrary: return "puzzlepiece.extension.fill"
        case .premiumBoard: return "paintpalette.fill"
        case .stats: return "chart.bar.fill"
        }
    }
}
