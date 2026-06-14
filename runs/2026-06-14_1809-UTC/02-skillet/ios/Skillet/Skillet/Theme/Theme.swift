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

/// Warm cookbook palette built around terracotta BD5B3A.
enum Theme {
    static let bg = Color.dyn(0xFBF5EC, 0x171210)          // warm cream paper / espresso
    static let surface = Color.dyn(0xFFFFFF, 0x231C18)      // card
    static let surfaceAlt = Color.dyn(0xF3E8DA, 0x2D2520)   // alt card
    static let ink = Color.dyn(0x2C1D14, 0xF5EDE3)          // primary text
    static let inkSoft = Color.dyn(0x6F5A4C, 0xC6B4A4)      // secondary text
    static let inkFaint = Color.dyn(0xA28C7C, 0x80695C)     // tertiary text
    static let accent = Color.dyn(0xBD5B3A, 0xD9744E)       // terracotta
    static let accentSoft = Color.dyn(0xF5E1D6, 0x3A241B)   // tinted fill
    static let hairline = Color.dyn(0xE8DAC9, 0x3B2E27)     // separators
    static let good = Color.dyn(0x3E8E5A, 0x67C28A)         // makeable / have
    static let bad = Color.dyn(0xBD5B3A, 0xD9744E)          // missing (terracotta)
    static let warn = Color.dyn(0xC2851E, 0xE2AB54)         // one-away amber

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
}
