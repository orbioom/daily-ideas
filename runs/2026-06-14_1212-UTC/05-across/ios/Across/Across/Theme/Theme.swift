import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    static func dyn(_ l: UInt, _ d: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? d : l
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

/// Across visual identity: a classic newspaper "puzzle page" — crisp grid,
/// warm newsprint paper in light, deep ink in dark, crossword-red accent.
/// The active theme can be switched (classic / ink / high-contrast) via Settings.
enum Theme {
    /// The currently selected board theme, set from AppSettings on app start and on change.
    /// Read by the grid renderer so cell/ink colors follow the chosen style.
    static var palette: ThemePalette = .classic

    // Chrome tokens (used app-wide, theme-independent so navigation stays consistent).
    static let bg = Color.dyn(0xF6F1E7, 0x14130F)          // newsprint paper / deep ink
    static let surface = Color.dyn(0xFFFFFF, 0x201E18)      // card
    static let surfaceAlt = Color.dyn(0xEFE8D8, 0x2A271F)  // alt card
    static let ink = Color.dyn(0x1E1B14, 0xF4F0E6)         // primary text
    static let inkSoft = Color.dyn(0x5E574A, 0xB8B2A2)     // secondary text
    static let inkFaint = Color.dyn(0x938A78, 0x736D5E)    // tertiary text
    static let accent = Color.dyn(0xC8472F, 0xE06A52)      // crossword red
    static let accentSoft = Color.dyn(0xF4DDD5, 0x3A211B)  // tinted fill
    static let hairline = Color.dyn(0xDDD4C0, 0x35322A)    // separators
    static let good = Color.dyn(0x3C7D54, 0x68C089)        // correct / positive
    static let bad = Color.dyn(0xC0492F, 0xE0795F)         // incorrect / destructive

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }

    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }
}

/// Board theming for the crossword grid. Affects only grid surfaces & letters,
/// so the rest of the app keeps its consistent chrome.
enum ThemePalette: String, CaseIterable, Identifiable {
    case classic     // newsprint paper + red highlights
    case ink         // cooler, higher-saturation slate
    case highContrast // bold black/white for accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "Classic"
        case .ink: return "Ink"
        case .highContrast: return "High Contrast"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: return "Warm newsprint paper"
        case .ink: return "Cool slate & crisp lines"
        case .highContrast: return "Maximum legibility"
        }
    }

    /// Empty (fillable) cell fill.
    var cellFill: Color {
        switch self {
        case .classic: return .dyn(0xFFFFFF, 0x232019)
        case .ink: return .dyn(0xFFFFFF, 0x1B2330)
        case .highContrast: return .dyn(0xFFFFFF, 0x000000)
        }
    }

    /// Block (#) cell fill.
    var blockFill: Color {
        switch self {
        case .classic: return .dyn(0x1E1B14, 0x000000)
        case .ink: return .dyn(0x16202C, 0x000000)
        case .highContrast: return .dyn(0x000000, 0xFFFFFF)
        }
    }

    /// Grid line color.
    var gridLine: Color {
        switch self {
        case .classic: return .dyn(0x2A261C, 0x4A4636)
        case .ink: return .dyn(0x223044, 0x44566E)
        case .highContrast: return .dyn(0x000000, 0xFFFFFF)
        }
    }

    /// Entered letter color.
    var letter: Color {
        switch self {
        case .classic: return .dyn(0x16130D, 0xF2EEE2)
        case .ink: return .dyn(0x14202E, 0xE6EEF8)
        case .highContrast: return .dyn(0x000000, 0xFFFFFF)
        }
    }

    /// Selected-cell highlight.
    var selected: Color {
        switch self {
        case .classic: return .dyn(0xF6C84A, 0x9A7A18)
        case .ink: return .dyn(0xF6C84A, 0x9A7A18)
        case .highContrast: return .dyn(0xFFD400, 0xB8A000)
        }
    }

    /// Highlight for the rest of the active slot.
    var slotHighlight: Color {
        switch self {
        case .classic: return .dyn(0xFCEFC2, 0x4A3B12)
        case .ink: return .dyn(0xCFE2FF, 0x223247)
        case .highContrast: return .dyn(0xFFF1A8, 0x3A3300)
        }
    }
}
