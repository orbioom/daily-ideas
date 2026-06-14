import Foundation

/// Free-tier limits and Pro gating logic.
///
/// Free solvers always get the daily puzzle plus a starter set of archive
/// puzzles. Across Pro is a one-time unlock for the full archive + extra themes.
enum Pro {
    /// How many archive puzzles (beyond the daily) free users may play.
    static let freeArchiveLimit = 6

    /// Display price for the one-time unlock.
    static let priceLabel = "$2.99"

    /// Whether a given archive puzzle (at the given position in the free order)
    /// is playable without Pro. The first `freeArchiveLimit` archive puzzles are
    /// free; the rest are gated.
    static func archiveUnlocked(freeIndex: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return freeIndex < freeArchiveLimit
    }

    /// Whether a non-classic palette is available.
    static func paletteUnlocked(_ palette: ThemePalette, isPro: Bool) -> Bool {
        if isPro { return true }
        return palette == .classic
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case archive
    case theme

    var id: String {
        switch self {
        case .archive: return "archive"
        case .theme: return "theme"
        }
    }

    var title: String {
        switch self {
        case .archive: return "Unlock the full archive"
        case .theme: return "Unlock every theme"
        }
    }

    var blurb: String {
        switch self {
        case .archive:
            return "Free Across includes today's puzzle plus \(Pro.freeArchiveLimit) from the archive. Go Pro for the entire library, forever."
        case .theme:
            return "The Ink and High Contrast board themes are part of Across Pro — a one-time unlock, no subscription."
        }
    }

    var symbol: String {
        switch self {
        case .archive: return "square.grid.3x3.fill"
        case .theme: return "paintpalette.fill"
        }
    }
}
