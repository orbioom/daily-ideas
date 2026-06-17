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

    /// A color that adapts between light and dark mode using raw hex values.
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

/// Cohesive visual identity for Tangle — a calm, paper-and-green word-game aesthetic.
enum Theme {
    /// MUST equal the AccentColor asset (0x2BB673 — fresh green).
    static let accent = Color(hex: 0x2BB673)
    static let accentDeep = Color.dyn(0x1F8E59, 0x37D78C)
    static let accentSoft = Color.dyn(0xCDEBDB, 0x123524)

    /// App background — soft warm paper in light, deep forest in dark.
    static let bg = Color.dyn(0xEAF6EF, 0x07140D)
    /// Card / panel surface.
    static let surface = Color.dyn(0xFFFFFF, 0x10241A)
    /// Slightly recessed surface (wheel well, empty tiles).
    static let surfaceSunken = Color.dyn(0xDCEEE3, 0x0B1C13)

    static let ink = Color.dyn(0x122019, 0xEAF6EF)
    static let inkSoft = Color.dyn(0x4C6B5B, 0x9FC2B1)
    static let hairline = Color.dyn(0xCBE2D5, 0x1E3A2A)

    static let good = Color.dyn(0x2BB673, 0x37D78C)
    static let warn = Color.dyn(0xE0922F, 0xF0B45A)
    static let bad = Color.dyn(0xD65745, 0xF08070)

    static let star = Color.dyn(0xF2B705, 0xFFD24A)

    static let heroGradient = LinearGradient(
        colors: [Color.dyn(0x39C982, 0x2BB673), Color.dyn(0x1F8E59, 0x14573A)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tileGradient = LinearGradient(
        colors: [Color.dyn(0xFFFFFF, 0x18382A), Color.dyn(0xEFF8F2, 0x12281C)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Corner radii
    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 24

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
