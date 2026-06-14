import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Per-colorScheme dynamic color (light hex, dark hex).
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

/// Tessera's "secure utility" design language. Indigo accent (#4C6FE0),
/// cool slate neutrals, mono/rounded numerals for codes. WCAG-AA in both modes.
enum Theme {
    static let bg = Color.dyn(0xF4F6FB, 0x0C0E14)          // cool paper / near-black slate
    static let surface = Color.dyn(0xFFFFFF, 0x161A24)      // card
    static let surfaceAlt = Color.dyn(0xEDF0F8, 0x1E2330)   // alt fill
    static let ink = Color.dyn(0x141A26, 0xF2F5FC)          // primary text
    static let inkSoft = Color.dyn(0x53607A, 0xA7B2C8)      // secondary text
    static let inkFaint = Color.dyn(0x8B97AE, 0x6B7488)     // tertiary text
    static let accent = Color.dyn(0x4C6FE0, 0x6E8BF0)       // indigo
    static let accentSoft = Color.dyn(0xE2E8FB, 0x1E2742)   // tinted fill
    static let hairline = Color.dyn(0xDFE4F0, 0x29303F)     // separators
    static let good = Color.dyn(0x1F9D6B, 0x49C893)         // positive
    static let warn = Color.dyn(0xC9871B, 0xE5B051)         // expiring / caution
    static let bad = Color.dyn(0xCB3A3A, 0xE57373)          // destructive

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    /// Monospaced numerals for codes so digits don't jitter as they roll.
    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    /// A palette of pleasant hues for account avatars, indexed by stored hue.
    static func accountColor(hue: Double) -> Color {
        let h = min(max(hue, 0), 1)
        return Color(hue: h, saturation: 0.55, brightness: 0.85)
    }
}
