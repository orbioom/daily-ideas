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

    /// Dynamic color that adapts to light / dark interface styles.
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

/// Thump visual identity — a sleek modern groovebox: dark slate panels,
/// neon-pink accents, glowing active steps, rounded numerals for BPM.
enum Theme {
    static let accent = Color(hex: 0xFF3D7F)        // hot magenta/pink (== AccentColor asset)
    static let accentSoft = Color(hex: 0xFF7AAB)

    static let bg = Color.dyn(0xF6EEF2, 0x120810)        // app background
    static let surface = Color.dyn(0xFFFFFF, 0x1E1420)   // panels / cards
    static let surfaceRaised = Color.dyn(0xFBF4F8, 0x271A2E)
    static let padBase = Color.dyn(0xE9DCE4, 0x2C1E33)   // inactive step pad
    static let padGroupAlt = Color.dyn(0xF1E6EC, 0x241730)

    static let ink = Color.dyn(0x1B1020, 0xF7EEF3)       // primary text
    static let inkSoft = Color.dyn(0x6E5C68, 0xB59AAE)   // secondary text
    static let hairline = Color.dyn(0xE0D2DB, 0x3A2A42)

    static let good = Color.dyn(0x1E9E6A, 0x46D9A0)
    static let warn = Color.dyn(0xCE8A12, 0xF2B53C)
    static let bad = Color.dyn(0xC4314B, 0xFF6B86)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0xFF3D7F), Color(hex: 0x9B2FB0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 14
    static let cornerSmall: CGFloat = 8

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Monospaced rounded numerals for BPM / counters.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
