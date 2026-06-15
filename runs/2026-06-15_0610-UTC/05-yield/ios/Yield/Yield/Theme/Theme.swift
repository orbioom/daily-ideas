import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// A color that resolves differently in light vs dark mode.
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

/// Yield's design language: a confident, calm fintech identity — emerald-green accent
/// on deep charcoal in dark, on soft paper in light. First-class in both schemes.
enum Theme {
    static let bg = Color.dyn(0xF3F6F4, 0x0C110E)            // app background
    static let surface = Color.dyn(0xFFFFFF, 0x161C18)        // card / panel
    static let surfaceAlt = Color.dyn(0xEAF1EC, 0x1E2722)     // alt surface / wells
    static let ink = Color.dyn(0x101814, 0xF1F6F2)           // primary text
    static let inkSoft = Color.dyn(0x53635B, 0xA8B6AC)       // secondary text
    static let inkFaint = Color.dyn(0x8A988F, 0x66766B)      // tertiary text
    static let accent = Color.dyn(0x169A5C, 0x33C77E)        // emerald accent
    static let accentSoft = Color.dyn(0xDCF1E6, 0x16321F)    // tinted fill
    static let hairline = Color.dyn(0xDEE7E1, 0x263029)      // separators
    static let good = Color.dyn(0x179A5C, 0x40D08A)          // positive / income
    static let warn = Color.dyn(0xC9852A, 0xE0A84B)          // caution
    static let bad = Color.dyn(0xCB4242, 0xEE6B6B)           // destructive

    /// Palette used for sector slices in charts (stable, color-blind-mindful order).
    static let chartPalette: [Color] = [
        Color.dyn(0x169A5C, 0x33C77E),
        Color.dyn(0x2C7BE5, 0x5C9BF0),
        Color.dyn(0xC9852A, 0xE0A84B),
        Color.dyn(0x7E57C2, 0xA383DA),
        Color.dyn(0x18A0A0, 0x3FC6C6),
        Color.dyn(0xCB4242, 0xEE6B6B),
        Color.dyn(0x5B6B7A, 0x8FA0AE),
        Color.dyn(0xB0508F, 0xD27CB6),
        Color.dyn(0x6F8A1E, 0x9DBC3C),
        Color.dyn(0xA8632C, 0xC9874B)
    ]

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}
