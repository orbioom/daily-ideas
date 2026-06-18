import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Dynamic color that resolves differently for light and dark mode.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((h >> 16) & 0xFF) / 255,
                green: CGFloat((h >> 8) & 0xFF) / 255,
                blue: CGFloat(h & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

/// Warm honeycomb / amber identity for Pangram.
enum Theme {
    /// Matches AccentColor.colorset (#E0A92B).
    static let accent = Color(hex: 0xE0A92B)
    static let accentDeep = Color.dyn(0xC4901C, 0xF0BE45)

    static let bg = Color.dyn(0xFFF7E6, 0x14100A)
    static let surface = Color.dyn(0xFFFFFF, 0x211B10)
    static let surfaceAlt = Color.dyn(0xFCEFD2, 0x2C2413)

    static let ink = Color.dyn(0x2A2110, 0xF6ECD6)
    static let inkSoft = Color.dyn(0x7A6A48, 0xB7A684)
    static let hairline = Color.dyn(0xEADCBE, 0x3A3120)

    static let good = Color.dyn(0x2E8B57, 0x5FCF8E)
    static let warn = Color.dyn(0xC77B1F, 0xE7B45A)
    static let bad = Color.dyn(0xB23A2E, 0xF08070)

    /// Honeycomb tile colors.
    static let hexCenter = Color(hex: 0xE0A92B)
    static let hexOuter = Color.dyn(0xFBE9C2, 0x33291A)
    static let hexOuterInk = Color.dyn(0x2A2110, 0xF6ECD6)

    /// Color-blind safe alternative for the center tile (high-contrast blue-amber pair).
    static let hexCenterCB = Color(hex: 0x3A7CA5)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0xF3C459), Color(hex: 0xE0A92B), Color(hex: 0xC4901C)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let cornerLarge: CGFloat = 22
    static let cornerMed: CGFloat = 14
    static let cornerSmall: CGFloat = 9

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
