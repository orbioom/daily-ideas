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

enum Theme {
    // Accent MUST equal the AccentColor asset (teal).
    static let accent = Color(hex: 0x1FB6A6)
    static let accentDeep = Color.dyn(0x148F84, 0x2BD3C1)

    // Backgrounds aligned to LaunchBackground asset.
    static let bg = Color.dyn(0xEAF6F5, 0x06140F)
    static let surface = Color.dyn(0xFFFFFF, 0x10241F)
    static let surfaceAlt = Color.dyn(0xF2FAF9, 0x16302A)

    static let ink = Color.dyn(0x0C1F1B, 0xEFF7F5)
    static let inkSoft = Color.dyn(0x4C615C, 0x9FB4AF)
    static let hairline = Color.dyn(0xD6E7E4, 0x223A34)

    static let good = Color.dyn(0x1E9E6A, 0x3FD08C)
    static let warn = Color.dyn(0xC8862A, 0xE7B25A)
    static let bad = Color.dyn(0xC4503D, 0xE57A66)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x1FB6A6), Color(hex: 0x148F84)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardCorner: CGFloat = 18
    static let chipCorner: CGFloat = 12

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A standard card surface used across the app for a cohesive look.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface() -> some View { modifier(CardBackground()) }
}
