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

    /// Dynamic color that resolves differently in light vs dark mode.
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
    /// Matches Assets AccentColor (#2E86DE) — friendly, energetic bright blue.
    static let accent = Color(hex: 0x2E86DE)
    static let accentDeep = Color.dyn(0x1B6FC4, 0x4F9FE6)

    static let bg = Color.dyn(0xEAF2FC, 0x06101C)
    static let surface = Color.dyn(0xFFFFFF, 0x0E1B2C)
    static let surfaceAlt = Color.dyn(0xF3F8FE, 0x12233A)

    static let ink = Color.dyn(0x16263A, 0xEAF2FC)
    static let inkSoft = Color.dyn(0x5A6B80, 0x9FB2C8)
    static let hairline = Color.dyn(0xDCE7F4, 0x1E3147)

    static let good = Color.dyn(0x2BA84A, 0x57D684)
    static let warn = Color.dyn(0xE08A1E, 0xF2B45A)
    static let bad = Color.dyn(0xD64550, 0xF07A83)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x2E86DE), Color(hex: 0x59B0F2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let cardRadius: CGFloat = 18
    static let chipRadius: CGFloat = 12

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
