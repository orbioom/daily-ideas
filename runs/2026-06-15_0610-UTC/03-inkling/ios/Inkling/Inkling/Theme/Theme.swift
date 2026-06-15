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

/// Inkling's design language: calm, clinical-but-warm, violet accent. A quiet paper
/// background with soft cards, gentle hairlines, and one confident accent. Light + dark
/// first-class via `Color.dyn`.
enum Theme {
    static let bg = Color.dyn(0xF6F4FB, 0x0E0C15)            // app background (warm paper / ink)
    static let surface = Color.dyn(0xFFFFFF, 0x1A1726)        // card / panel
    static let surfaceAlt = Color.dyn(0xF0ECF8, 0x231F33)     // alt surface / inset
    static let ink = Color.dyn(0x191527, 0xF3F0FA)           // primary text
    static let inkSoft = Color.dyn(0x5A5470, 0xB3ACC6)       // secondary text
    static let inkFaint = Color.dyn(0x938CAA, 0x6C6584)      // tertiary text
    static let accent = Color.dyn(0x7C5CFF, 0x9C84FF)        // violet accent
    static let accentDeep = Color.dyn(0x5E3FE0, 0xB6A4FF)    // pressed / emphasis
    static let accentSoft = Color.dyn(0xEBE5FF, 0x2A2342)    // tinted fill
    static let hairline = Color.dyn(0xE6E1F2, 0x2C2740)      // separators
    static let good = Color.dyn(0x1F9D6B, 0x53D39B)          // positive / success
    static let warn = Color.dyn(0xC9821F, 0xF0B45A)          // caution / low confidence
    static let bad = Color.dyn(0xD2453F, 0xF07A74)           // negative / destructive

    /// Correlation directional hues — warm for positive, cool teal for negative.
    static let positive = Color.dyn(0xD2453F, 0xF07A74)      // a factor that *raises* a symptom
    static let negative = Color.dyn(0x1F8FA8, 0x55C6DD)      // a factor that *lowers* a symptom

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}
