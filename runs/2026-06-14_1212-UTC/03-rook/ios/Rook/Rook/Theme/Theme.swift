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

/// Tournament-chess design language built around emerald (#2E9E6B) with walnut/cream touches.
enum Theme {
    static let bg = Color.dyn(0xF7F3EA, 0x14130F)          // warm cream paper / near-black
    static let surface = Color.dyn(0xFFFFFF, 0x1F1D17)      // card
    static let surfaceAlt = Color.dyn(0xF0E9DA, 0x29251D)   // alt card
    static let ink = Color.dyn(0x23201A, 0xF4EFE3)          // primary text
    static let inkSoft = Color.dyn(0x6A6354, 0xBDB4A2)      // secondary text
    static let inkFaint = Color.dyn(0x9A9180, 0x7A7263)     // tertiary text
    static let accent = Color.dyn(0x2E9E6B, 0x46C089)       // emerald
    static let accentSoft = Color.dyn(0xDCEFE4, 0x1E3A2C)   // tinted fill
    static let hairline = Color.dyn(0xE3DACA, 0x33302A)     // separators
    static let good = Color.dyn(0x2E9E6B, 0x46C089)         // positive
    static let bad = Color.dyn(0xB8442E, 0xDB7558)          // negative / destructive
    static let gold = Color.dyn(0xB08442, 0xD4A95F)         // accent gold trim

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
}

/// Selectable board color palettes. Light/dark squares plus highlight tints.
enum BoardTheme: String, CaseIterable, Identifiable, Codable {
    case walnut
    case green
    case blue
    case gray

    var id: String { rawValue }

    var label: String {
        switch self {
        case .walnut: return "Walnut"
        case .green: return "Tournament Green"
        case .blue: return "Slate Blue"
        case .gray: return "Newsprint Gray"
        }
    }

    /// Whether this theme is part of the Pro premium set.
    var isPremium: Bool {
        switch self {
        case .walnut, .green: return false
        case .blue, .gray: return true
        }
    }

    var lightSquare: Color {
        switch self {
        case .walnut: return Color(hex: 0xEDD9B5)
        case .green: return Color(hex: 0xEEEED2)
        case .blue: return Color(hex: 0xDEE3E6)
        case .gray: return Color(hex: 0xE8E8E8)
        }
    }

    var darkSquare: Color {
        switch self {
        case .walnut: return Color(hex: 0xA9743C)
        case .green: return Color(hex: 0x769656)
        case .blue: return Color(hex: 0x7D93A6)
        case .gray: return Color(hex: 0x9A9A9A)
        }
    }

    /// Last-move highlight overlay.
    var highlight: Color { Color(hex: 0xE6C84A).opacity(0.55) }
    /// Selected-square overlay.
    var selection: Color { Theme.accent.opacity(0.45) }
    /// In-check king square overlay.
    var checkTint: Color { Color(hex: 0xD64A3A).opacity(0.7) }
    /// Legal-move dot color.
    var dot: Color { Color.black.opacity(0.28) }

    var frame: Color {
        switch self {
        case .walnut: return Color(hex: 0x6E4824)
        case .green: return Color(hex: 0x3E5536)
        case .blue: return Color(hex: 0x4A5A66)
        case .gray: return Color(hex: 0x555555)
        }
    }
}

/// Visual weight for the piece glyphs.
enum PieceStyle: String, CaseIterable, Identifiable, Codable {
    case classic   // outlined-feel via shadow + light fill for white
    case bold      // heavier solid glyphs

    var id: String { rawValue }
    var label: String { self == .classic ? "Classic" : "Bold" }
}
