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

/// Warm editorial "perfumery" palette built around amber-gold C8902A.
enum Theme {
    static let bg = Color.dyn(0xFAF4EA, 0x14110C)          // warm parchment / deep noir
    static let surface = Color.dyn(0xFFFFFF, 0x201B13)      // card
    static let surfaceAlt = Color.dyn(0xF1E7D5, 0x2A2318)   // alt card
    static let ink = Color.dyn(0x271F12, 0xF4ECDD)          // primary text
    static let inkSoft = Color.dyn(0x6A5C44, 0xBEB096)      // secondary text
    static let inkFaint = Color.dyn(0x9C8E73, 0x7E7058)     // tertiary text
    static let accent = Color.dyn(0xC8902A, 0xDDA945)       // amber-gold
    static let accentSoft = Color.dyn(0xF4E7C8, 0x352B17)   // tinted fill
    static let hairline = Color.dyn(0xE6DAC2, 0x36301F)     // separators
    static let good = Color.dyn(0x4F8A56, 0x7CC084)         // positive
    static let bad = Color.dyn(0xB5462F, 0xDB7A63)          // negative / destructive

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    /// Serif accents give Sillage its editorial "perfumery" voice.
    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
}
