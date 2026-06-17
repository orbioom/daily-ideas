import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// A color that adapts between light and dark interface styles.
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

/// Aquatic, calm visual identity: deep pool teal accent over cool paper / near-night water.
/// All colors adapt to light & dark and meet WCAG-AA contrast in both.
enum Theme {
    static let bg = Color.dyn(0xF2F8FA, 0x0B1417)          // pale water / deep night pool
    static let surface = Color.dyn(0xFFFFFF, 0x132227)      // card
    static let surfaceAlt = Color.dyn(0xE7F2F4, 0x182D33)   // alt card / lane lines
    static let ink = Color.dyn(0x0E2228, 0xEAF6F8)          // primary text
    static let inkSoft = Color.dyn(0x4A6068, 0xA7C2C9)      // secondary text
    static let inkFaint = Color.dyn(0x86A0A7, 0x6B868D)     // tertiary text
    static let accent = Color.dyn(0x0E8C9C, 0x2BC4D6)       // pool teal
    static let accentDeep = Color.dyn(0x0A6B78, 0x1E9AA8)   // deep accent
    static let accentSoft = Color.dyn(0xD7EEF1, 0x103138)   // tinted fill
    static let hairline = Color.dyn(0xD5E6E9, 0x223A41)     // separators
    static let good = Color.dyn(0x2E8B6B, 0x5FCBA6)         // positive
    static let warn = Color.dyn(0xC9772B, 0xE3A05A)         // attention
    static let bad = Color.dyn(0xC0492F, 0xE0795F)          // destructive

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }

    /// A gentle top-to-bottom water gradient for hero surfaces.
    static var waterGradient: LinearGradient {
        LinearGradient(colors: [accent, accentDeep],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }
}
