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

    /// Dynamic color that adapts to light/dark mode for WCAG-friendly contrast.
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

/// Glint's "jewel studio" identity: deep amethyst/violet, faceted-gem brights, rounded fonts.
enum Theme {
    static let accent = Color(hex: 0x8B5CF6)

    static let bg = Color.dyn(0xF5F2FF, 0x140C26)
    static let surface = Color.dyn(0xFFFFFF, 0x231640)
    static let surfaceRaised = Color.dyn(0xF1ECFF, 0x2E1F52)
    static let ink = Color.dyn(0x1E1233, 0xF4EEFF)
    static let inkSoft = Color.dyn(0x6A5A87, 0xB6A7D6)
    static let hairline = Color.dyn(0xE5DCFA, 0x3A2A60)

    static let good = Color.dyn(0x18A058, 0x4ADE80)
    static let warn = Color.dyn(0xD9820B, 0xFBBF24)
    static let bad = Color.dyn(0xD6336C, 0xFB7185)

    static let gold = Color(hex: 0xFFC93C)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x8B5CF6), Color(hex: 0xC026D3), Color(hex: 0x6366F1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let calmGradient = LinearGradient(
        colors: [Color(hex: 0x5B21B6), Color(hex: 0x312E81)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Corner radii
    static let rSmall: CGFloat = 10
    static let rMed: CGFloat = 16
    static let rLarge: CGFloat = 24
    static let rGem: CGFloat = 12

    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
}
