import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Resolves to `l` in light mode and `d` in dark mode.
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

/// Bold "iron gym" palette: steel + warm amber. WCAG-AA in both schemes.
enum Theme {
    static let bg = Color.dyn(0xF4F1EC, 0x121316)          // steel paper / near-black graphite
    static let surface = Color.dyn(0xFFFFFF, 0x1E2026)     // card
    static let surfaceAlt = Color.dyn(0xEAE6DE, 0x282B33)  // alt card / rail
    static let ink = Color.dyn(0x1B1D22, 0xF3F1EC)         // primary text
    static let inkSoft = Color.dyn(0x5A5E66, 0xB6B9C0)     // secondary text
    static let inkFaint = Color.dyn(0x8B8F98, 0x767A83)    // tertiary text
    static let accent = Color.dyn(0xC97A12, 0xF2A53C)      // forged amber
    static let accentSoft = Color.dyn(0xF6E7CC, 0x332712) // tinted fill
    static let steel = Color.dyn(0x3C4250, 0x9AA3B2)       // cool steel accent
    static let hairline = Color.dyn(0xDDD8CE, 0x32353D)    // separators
    static let good = Color.dyn(0x2F7D4F, 0x5FC487)        // positive / PR
    static let bad = Color.dyn(0xB23B2A, 0xE0795F)         // negative / destructive

    /// Big numeral / display font — rounded, heavy, tactile.
    static func num(_ s: CGFloat, _ w: Font.Weight = .bold) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
}
