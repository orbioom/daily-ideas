import SwiftUI

extension Color {
    /// Build a color from a 24-bit RGB hex literal, e.g. `Color(hex: 0xF2792B)`.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Dynamic color that resolves differently in light vs dark mode.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { trait in
            let h = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((h >> 16) & 0xFF) / 255,
                green: CGFloat((h >> 8) & 0xFF) / 255,
                blue: CGFloat(h & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

/// Crisp visual identity — warm, appetizing, kitchen-friendly. Hot-orange accent,
/// big legible rounded numbers, soft food-card surfaces.
enum Theme {
    static let accent = Color(hex: 0xF2792B)
    static let accentDeep = Color.dyn(0xD9621A, 0xFF8A3D)

    static let bg = Color.dyn(0xFFF2E8, 0x160C04)
    static let surface = Color.dyn(0xFFFFFF, 0x261408)
    static let surfaceAlt = Color.dyn(0xFFE7D4, 0x301A0A)

    static let ink = Color.dyn(0x2B1A0E, 0xFCEFE3)
    static let inkSoft = Color.dyn(0x7A5A42, 0xC9A98E)
    static let hairline = Color.dyn(0xEAD3BD, 0x3D2410)

    static let good = Color.dyn(0x2E8B57, 0x53D08A)
    static let warn = Color.dyn(0xC9821B, 0xF0B459)
    static let bad = Color.dyn(0xC2382B, 0xF26257)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0xF2792B), Color(hex: 0xE8541C)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let cardRadius: CGFloat = 20
    static let chipRadius: CGFloat = 14
    static let tileRadius: CGFloat = 18

    /// Rounded system font helper — used everywhere for the friendly kitchen feel.
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Scalable rounded font tied to a Dynamic Type text style.
    static func roundedStyle(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}
