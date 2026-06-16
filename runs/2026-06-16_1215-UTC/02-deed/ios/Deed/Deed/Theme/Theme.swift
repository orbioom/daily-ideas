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

    /// Dynamic color that resolves differently in light and dark mode.
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

enum Theme {
    /// Must equal the AccentColor asset (0x2E8B6B).
    static let accent = Color(hex: 0x2E8B6B)
    static let accentDeep = Color.dyn(0x216E54, 0x3FA886)

    static let bg = Color.dyn(0xF5F7F5, 0x0E1512)
    static let surface = Color.dyn(0xFFFFFF, 0x18211D)
    static let surfaceAlt = Color.dyn(0xEEF2EF, 0x202B26)

    static let ink = Color.dyn(0x16201B, 0xF1F5F2)
    static let inkSoft = Color.dyn(0x5A6660, 0xA6B3AC)
    static let inkFaint = Color.dyn(0x8B968F, 0x6E7A73)

    static let hairline = Color.dyn(0xE2E8E4, 0x2C3833)

    static let good = Color.dyn(0x1E8E5A, 0x4FD08E)
    static let warn = Color.dyn(0xC9871A, 0xF0B84B)
    static let bad = Color.dyn(0xC0392B, 0xF07167)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x2E8B6B), Color(hex: 0x1F6E63)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let radiusS: CGFloat = 10
    static let radiusM: CGFloat = 16
    static let radiusL: CGFloat = 22

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Deterministic gradient palette used for property identity colors.
    static let identityPalette: [UInt] = [
        0x2E8B6B, 0x3C6E9E, 0x9E5A3C, 0x6E4C9E,
        0x9E3C6E, 0x3C9E8B, 0x9E8B3C, 0x4C6E3C
    ]
}
