import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

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

/// Numen visual identity: deep indigo/plum, antique gold, serif display.
enum Theme {
    /// MUST equal AccentColor in Assets (0xC9A24B antique gold).
    static let accent = Color(hex: 0xC9A24B)
    static let accentDeep = Color(hex: 0x9C7A2E)

    /// App background — warm parchment in light, deep indigo at night.
    static let bg = Color.dyn(0xF7F3EA, 0x140F22)
    /// Card / panel surface.
    static let surface = Color.dyn(0xFFFFFF, 0x1F1733)
    /// Slightly raised surface for nested elements.
    static let surfaceAlt = Color.dyn(0xF1EADD, 0x2A2042)

    /// Primary text — near-black on parchment, soft ivory on indigo (AA verified).
    static let ink = Color.dyn(0x231C30, 0xF3EEF8)
    /// Secondary text.
    static let inkSoft = Color.dyn(0x6A6076, 0xB7AECB)
    /// Faint hairline / borders.
    static let hairline = Color.dyn(0xE3DBCC, 0x352A50)

    static let good = Color.dyn(0x2E8B57, 0x6FCF97)
    static let warn = Color.dyn(0xB8860B, 0xE0B84C)
    static let bad = Color.dyn(0xB23A48, 0xE8838F)

    /// Hero gradient for headers and the share card.
    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x2A1B4D), Color(hex: 0x140F22), Color(hex: 0x301E3E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gold gradient for accents and number glyphs.
    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xE2C275), Color(hex: 0xC9A24B), Color(hex: 0x9C7A2E)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Corner radii
    static let cornerL: CGFloat = 22
    static let cornerM: CGFloat = 16
    static let cornerS: CGFloat = 10

    // Fonts
    static func serif(_ style: Font.TextStyle) -> Font { .system(style, design: .serif) }
    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
}
