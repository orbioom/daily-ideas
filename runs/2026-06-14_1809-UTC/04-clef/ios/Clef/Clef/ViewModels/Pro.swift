import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can run drills up to this length (and Timed mode is Pro-only).
    static let freeMaxLength = 20

    /// Display price for the one-time unlock.
    static let priceLabel = "$4.99"

    /// Whether a clef is available to a (possibly free) user.
    static func clefAllowed(_ clef: Clef, isPro: Bool) -> Bool {
        if isPro { return true }
        return !clef.requiresPro
    }

    /// Whether a drill length value is allowed for a free user.
    static func lengthAllowed(_ count: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return count <= freeMaxLength
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case clefs
    case accidentals
    case timed
    case fullRange
    case export

    var id: String {
        switch self {
        case .clefs: return "clefs"
        case .accidentals: return "accidentals"
        case .timed: return "timed"
        case .fullRange: return "fullRange"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .clefs: return "Unlock every clef"
        case .accidentals: return "Practice sharps & flats"
        case .timed: return "Race the clock"
        case .fullRange: return "Open the full range"
        case .export: return "Export your stats"
        }
    }

    var blurb: String {
        switch self {
        case .clefs:
            return "Free Clef trains the treble clef. Go Pro to read bass, alto, and the grand staff."
        case .accidentals:
            return "Add the black keys — sharps and flats — to sharpen your reading."
        case .timed:
            return "Unlock the 60-second timed sprint and chase your best run."
        case .fullRange:
            return "Drill ledger-line notes far above and below the staff."
        case .export:
            return "Copy your full practice history and per-note mastery as clean text."
        }
    }

    var symbol: String {
        switch self {
        case .clefs: return "music.note.list"
        case .accidentals: return "number"
        case .timed: return "timer"
        case .fullRange: return "arrow.up.and.down"
        case .export: return "square.and.arrow.up"
        }
    }
}
