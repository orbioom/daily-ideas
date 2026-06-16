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

    /// Dynamic color that adapts to light/dark mode. Both values chosen for AA contrast.
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

/// Lane's visual identity: a crisp, calm "blueprint" feel — cool slate surfaces,
/// a confident azure accent, rounded type. Reads well in both modes.
enum Theme {
    /// MUST equal the AccentColor asset (0x2D7FF9).
    static let accent = Color(hex: 0x2D7FF9)
    static let accentSoft = Color.dyn(0xE4F0FF, 0x12325C)

    static let bg = Color.dyn(0xF4F6FA, 0x0E1117)
    static let surface = Color.dyn(0xFFFFFF, 0x1A1F29)
    static let surfaceAlt = Color.dyn(0xEEF1F7, 0x232A36)
    static let ink = Color.dyn(0x101725, 0xF2F5FA)
    static let inkSoft = Color.dyn(0x5A6473, 0x9AA6B6)
    static let hairline = Color.dyn(0xDDE3EC, 0x2C3543)

    static let good = Color.dyn(0x18A957, 0x3DDC84)
    static let warn = Color.dyn(0xD68A00, 0xF5B845)
    static let bad = Color.dyn(0xD23B3B, 0xFF6B6B)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x2D7FF9), Color(hex: 0x6B5BFF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    enum Radius {
        static let card: CGFloat = 16
        static let chip: CGFloat = 12
        static let pill: CGFloat = 999
    }
}
