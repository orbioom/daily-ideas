import SwiftUI

extension Color {
    /// Build a color from a 0xRRGGBB literal.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Dynamic color that resolves differently for light and dark mode.
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

/// Centralized visual identity for Pursuit. Indigo / ink palette with rounded type.
enum Theme {
    // Brand accent — MUST match the AccentColor asset (0x4C5BD4).
    static let accent = Color(hex: 0x4C5BD4)
    static let accentSoft = Color.dyn(0xE7E9FB, 0x262B5C)

    // Backgrounds & surfaces
    static let bg = Color.dyn(0xF6F7FB, 0x0E1018)
    static let surface = Color.dyn(0xFFFFFF, 0x191C28)
    static let surfaceAlt = Color.dyn(0xF0F2F8, 0x212534)
    static let elevated = Color.dyn(0xFFFFFF, 0x222637)

    // Text
    static let ink = Color.dyn(0x141627, 0xF4F5FB)
    static let inkSoft = Color.dyn(0x5A5E73, 0xA6AAC0)
    static let inkFaint = Color.dyn(0x9094AB, 0x6A6E86)

    // Lines
    static let hairline = Color.dyn(0xE3E5EE, 0x2C3042)

    // Semantic
    static let good = Color.dyn(0x1F9D5B, 0x39C77E)
    static let warn = Color.dyn(0xC9871A, 0xF0B43C)
    static let bad = Color.dyn(0xCB3A4A, 0xF06A78)
    static let info = Color.dyn(0x2C6FD6, 0x5B9BF5)

    // Hero gradient used on onboarding / summary cards
    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x4C5BD4), Color(hex: 0x6E5BD4), Color(hex: 0x3E8BD0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Corner radii
    static let radiusS: CGFloat = 10
    static let radiusM: CGFloat = 16
    static let radiusL: CGFloat = 24

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Card container used throughout the app for a consistent surface treatment.
struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = Theme.radiusM
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16, radius: CGFloat = Theme.radiusM) -> some View {
        modifier(CardModifier(padding: padding, radius: radius))
    }
}
