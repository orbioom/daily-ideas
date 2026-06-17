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
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

/// Scholarly-but-friendly palette built around the indigo/violet accent (0x6357D8).
enum Theme {
    static let bg = Color.dyn(0xEFEEFB, 0x0B0A18)          // soft lilac paper / near-black indigo
    static let surface = Color.dyn(0xFFFFFF, 0x171528)      // card
    static let surfaceAlt = Color.dyn(0xF4F3FD, 0x201D33)   // alt card / fills
    static let ink = Color.dyn(0x1E1B33, 0xF1EFFA)          // primary text
    static let inkSoft = Color.dyn(0x5A5476, 0xB6B0CF)      // secondary text
    static let inkFaint = Color.dyn(0x8C87A6, 0x726C8C)     // tertiary text
    static let accent = Color.dyn(0x6357D8, 0x8C82EE)       // indigo / violet
    static let accentSoft = Color.dyn(0xE6E3FB, 0x2A2548)   // tinted fill
    static let hairline = Color.dyn(0xE0DDF3, 0x2C2842)     // separators
    static let good = Color.dyn(0x2F9E66, 0x5FD497)         // correct
    static let bad = Color.dyn(0xC73B4E, 0xF07A8A)          // incorrect / destructive
    static let gold = Color.dyn(0xC98A1E, 0xE7B85C)         // mastered accent

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
}
