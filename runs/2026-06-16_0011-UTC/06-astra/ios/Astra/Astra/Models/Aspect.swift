import SwiftUI

/// The major Ptolemaic aspects Astra recognizes.
enum AspectKind: String, CaseIterable, Identifiable {
    case conjunction = "Conjunction"
    case sextile = "Sextile"
    case square = "Square"
    case trine = "Trine"
    case opposition = "Opposition"

    var id: String { rawValue }

    /// Exact angular separation in degrees.
    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        }
    }

    var glyph: String {
        switch self {
        case .conjunction: return "\u{260C}"
        case .sextile: return "\u{26B9}"
        case .square: return "\u{25A1}"
        case .trine: return "\u{25B3}"
        case .opposition: return "\u{260D}"
        }
    }

    /// Harmonious aspects ease energy between two bodies.
    var isHarmonious: Bool {
        switch self {
        case .sextile, .trine: return true
        case .conjunction: return true   // depends, but counted as flowing for scoring
        case .square, .opposition: return false
        }
    }

    /// Challenging aspects create tension and growth.
    var isChallenging: Bool {
        self == .square || self == .opposition
    }

    var color: Color {
        switch self {
        case .conjunction: return Theme.gold
        case .sextile, .trine: return Theme.good
        case .square, .opposition: return Theme.bad
        }
    }

    var meaning: String {
        switch self {
        case .conjunction:
            return "Two forces fused — they act as one, intensifying each other for better or worse."
        case .sextile:
            return "An open door. Easy cooperation that rewards a little effort to walk through it."
        case .square:
            return "Friction that forces growth. The two pull against each other until you build a way to hold both."
        case .trine:
            return "A natural flow. Talent that comes so easily it can be taken for granted."
        case .opposition:
            return "A tug-of-war across the chart. Balance is found by honoring both ends, not picking one."
        }
    }

    /// The default orb (allowed deviation) for this aspect, widened for luminaries.
    func orb(involvingLuminary: Bool, base: Double) -> Double {
        involvingLuminary ? base + 2 : base
    }
}

/// A computed aspect between two bodies in one chart (or across two for synastry).
struct AspectHit: Identifiable {
    let id = UUID()
    let a: Planet
    let b: Planet
    let kind: AspectKind
    /// How far from exact, in degrees (0 = perfectly exact).
    let orb: Double
    /// True when the bodies are moving toward exactness.
    let applying: Bool

    var exactness: String {
        String(format: "%.1f\u{00B0} orb", orb)
    }
}
