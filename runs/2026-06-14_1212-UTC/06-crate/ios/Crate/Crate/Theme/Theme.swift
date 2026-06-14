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

/// Crate's warm "record-store / crate-digging" design language.
/// Built around burnt-orange D2772E with analog, paper-and-vinyl warmth.
enum Theme {
    static let bg = Color.dyn(0xF6EFE6, 0x141210)          // warm paper / near-black wax
    static let surface = Color.dyn(0xFFFBF4, 0x201D1A)      // card
    static let surfaceAlt = Color.dyn(0xEFE5D6, 0x2A2521)   // alt card / shelf
    static let ink = Color.dyn(0x251D14, 0xF4EDE2)          // primary text
    static let inkSoft = Color.dyn(0x6B5A49, 0xC2B3A2)      // secondary text
    static let inkFaint = Color.dyn(0x9C8B79, 0x80705F)     // tertiary text
    static let accent = Color.dyn(0xC2671F, 0xE08A3C)       // burnt orange D2772E family
    static let accentSoft = Color.dyn(0xF6E4D0, 0x3A2A1A)   // tinted fill
    static let hairline = Color.dyn(0xE3D6C3, 0x352E27)     // separators
    static let good = Color.dyn(0x3E7E55, 0x6BBE89)         // positive
    static let bad = Color.dyn(0xB6452C, 0xDD7B60)          // negative / destructive
    static let wax = Color.dyn(0x1B1714, 0x0C0A09)          // vinyl disc body
    static let waxGroove = Color.dyn(0x2E2722, 0x1C1916)    // vinyl groove sheen

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }

    /// A deterministic two-stop gradient for a record's cover label, derived from a 0...1 hue.
    static func coverGradient(hue: Double) -> LinearGradient {
        let h = max(0, min(1, hue))
        let base = Color(hue: h, saturation: 0.55, brightness: 0.72)
        let lighter = Color(hue: (h + 0.06).truncatingRemainder(dividingBy: 1.0),
                            saturation: 0.46, brightness: 0.86)
        return LinearGradient(colors: [lighter, base],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }
}
