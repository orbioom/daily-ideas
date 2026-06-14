import Foundation

/// Free-tier limits and Pro gating. Free: full classic, today's daily, and stats.
/// Pro unlocks premium color themes, unlimited Undo, and the Daily Challenge archive.
enum Pro {
    static let priceLabel = "$2.99"

    /// Free players get this many undos per game; Pro is unlimited.
    static let freeUndoLimit = 3

    static func undoLimitLabel(isPro: Bool) -> String {
        isPro ? "Unlimited" : "\(freeUndoLimit) per game"
    }

    /// Remaining undos for the current game (nil = unlimited for Pro).
    static func remainingUndos(used: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeUndoLimit - used, 0)
    }

    static func canUndo(used: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return used < freeUndoLimit
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case themes
    case undo
    case dailyArchive

    var id: String {
        switch self {
        case .themes: return "themes"
        case .undo: return "undo"
        case .dailyArchive: return "dailyArchive"
        }
    }

    var title: String {
        switch self {
        case .themes: return "Unlock premium color themes"
        case .undo: return "Out of free undos"
        case .dailyArchive: return "Open the Daily archive"
        }
    }

    var blurb: String {
        switch self {
        case .themes:
            return "Cobble Pro adds hand-tuned block palettes — Sunset, Forest, and Candy — alongside the free Cobble set."
        case .undo:
            return "Free play includes \(Pro.freeUndoLimit) undos per game. Go Pro for unlimited undos so a misplaced piece is never the end."
        case .dailyArchive:
            return "Today's Daily is always free. Cobble Pro unlocks every past day so you can catch up on the ones you missed."
        }
    }

    var symbol: String {
        switch self {
        case .themes: return "paintpalette.fill"
        case .undo: return "arrow.uturn.backward.circle.fill"
        case .dailyArchive: return "calendar.badge.clock"
        }
    }
}
