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

enum Theme {
    // Warm editorial palette built around tomato red D94F3D.
    static let bg = Color.dyn(0xFBF6F0, 0x16100E)          // warm paper / near-black espresso
    static let surface = Color.dyn(0xFFFFFF, 0x221A17)      // card
    static let surfaceAlt = Color.dyn(0xF4EBE1, 0x2C221E)   // alt card
    static let ink = Color.dyn(0x2A1B16, 0xF6EEE7)          // primary text
    static let inkSoft = Color.dyn(0x6E5A50, 0xC4B2A6)      // secondary text
    static let inkFaint = Color.dyn(0xA08C80, 0x7C6A60)     // tertiary text
    static let accent = Color.dyn(0xD94F3D, 0xE8654F)       // tomato red
    static let accentSoft = Color.dyn(0xF7E2DC, 0x3A211C)   // tinted fill
    static let hairline = Color.dyn(0xE7DACE, 0x3A2E29)     // separators
    static let good = Color.dyn(0x3E8E5A, 0x67C28A)         // positive
    static let bad = Color.dyn(0xC0492F, 0xE0795F)          // negative / destructive

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
}
