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

    /// Dynamic color that resolves differently in light vs dark mode (WCAG-AA tuned per pair).
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

/// Hark's visual identity: calm, clinical-but-warm indigo. Soft surfaces, generous spacing.
enum Theme {
    /// MUST equal AccentColor in Assets.xcassets (0x5B6CF0).
    static let accent = Color(hex: 0x5B6CF0)
    static let accentSoft = Color.dyn(0xEAEDFE, 0x232746)

    static let bg = Color.dyn(0xF6F7FC, 0x0E0F1A)
    static let surface = Color.dyn(0xFFFFFF, 0x191B2B)
    static let surfaceAlt = Color.dyn(0xF0F2FA, 0x202338)

    static let ink = Color.dyn(0x161826, 0xF4F5FB)
    static let inkSoft = Color.dyn(0x5A5F73, 0x9FA4BD)
    static let hairline = Color.dyn(0xE3E6F0, 0x2C2F45)

    static let good = Color.dyn(0x2E9E6B, 0x57D6A0)
    static let warn = Color.dyn(0xC98A1E, 0xE7B85A)
    static let bad = Color.dyn(0xC4504F, 0xE88A89)

    /// Per-ear palette used consistently across audiogram and history.
    static let earRight = Color(hex: 0xE07A5F) // conventional "red = right"
    static let earLeft = Color(hex: 0x4F6BED) // conventional "blue = left"

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x5B6CF0), Color(hex: 0x7E5BF0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let rCard: CGFloat = 20
    static let rChip: CGFloat = 12
    static let rButton: CGFloat = 16

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
}
