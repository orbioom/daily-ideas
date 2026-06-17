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

    /// Returns a dynamic color that adapts to light/dark interface styles.
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

/// Warm, playful, kid-friendly theme. Accent equals the AccentColor asset (0xFF8A4C).
enum Theme {
    static let accent = Color(hex: 0xFF8A4C)
    static let accentSoft = Color.dyn(0xFFD9C2, 0x6B3A1E)
    static let accentDeep = Color.dyn(0xE56A2C, 0xFFA266)

    static let bg = Color.dyn(0xFFF3EA, 0x1A0E06)
    static let surface = Color.dyn(0xFFFFFF, 0x2A1A10)
    static let surfaceAlt = Color.dyn(0xFFF9F2, 0x352013)

    static let ink = Color.dyn(0x3B2415, 0xFBEFE4)
    static let inkSoft = Color.dyn(0x8A6B55, 0xC9A98F)
    static let hairline = Color.dyn(0xEAD9C8, 0x4A3322)

    static let good = Color.dyn(0x3DAE6B, 0x6FE0A0)
    static let warn = Color.dyn(0xE0A100, 0xFFD24D)
    static let bad = Color.dyn(0xD8543B, 0xFF8A70)

    static let star = Color(hex: 0xFFC23C)
    static let sky = Color.dyn(0x7EC8E3, 0x2F6E86)
    static let grass = Color.dyn(0x8FD17A, 0x3E6E33)
    static let berry = Color.dyn(0xE07AA8, 0x8E3E62)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0xFFB37A), Color(hex: 0xFF8A4C)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii.
    static let radiusSmall: CGFloat = 14
    static let radiusMedium: CGFloat = 22
    static let radiusLarge: CGFloat = 32

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
