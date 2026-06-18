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

    /// A color that resolves differently in light and dark mode.
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

/// Warm, photographic, editorial identity — soft coral accent, generous photo
/// cards, rounded system font that reads almost serif-ish, film-like surfaces.
enum Theme {
    /// Soft coral. MUST equal the AccentColor in Assets (#F2664B).
    static let accent = Color(hex: 0xF2664B)
    static let accentSoft = Color.dyn(0xFADAD2, 0x3A2520)

    /// Warm paper / near-black film base.
    static let bg = Color.dyn(0xFFF1EC, 0x16100E)
    static let surface = Color.dyn(0xFFFFFF, 0x221A17)
    static let surfaceAlt = Color.dyn(0xFCE7DF, 0x2C211C)

    static let ink = Color.dyn(0x2A1C17, 0xF4E9E3)
    static let inkSoft = Color.dyn(0x8A6F64, 0xB9A398)
    static let hairline = Color.dyn(0xEAD7CD, 0x3A2C26)

    static let good = Color.dyn(0x2E9E6B, 0x6FD3A2)
    static let warn = Color.dyn(0xCF8A28, 0xF0BE6B)
    static let bad = Color.dyn(0xC8503C, 0xF09480)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0xF2664B), Color(hex: 0xF09A5A), Color(hex: 0xE0567E)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let cardRadius: CGFloat = 22
    static let chipRadius: CGFloat = 13
    static let tileRadius: CGFloat = 14

    /// Rounded system font (our "serif-ish" editorial voice).
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let sectionFont = Font.system(.title3, design: .rounded).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.subheadline, design: .rounded)
}
