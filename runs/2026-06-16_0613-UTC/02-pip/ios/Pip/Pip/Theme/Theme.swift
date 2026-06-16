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

    /// Dynamic color that resolves to `light` or `dark` hex depending on the trait collection.
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

/// Pip's visual identity: a clean, modern "green felt" card table.
/// Emerald accent, ivory/cream dice, warm ink, rounded type. Calm, not casino.
enum Theme {
    /// MUST equal the AccentColor color set (0x18A558).
    static let accent = Color(hex: 0x18A558)
    static let accentDeep = Color(hex: 0x0F7A40)
    static let accentSoft = Color.dyn(0xD6F0E1, 0x123A28)

    /// App background — soft ivory in light, deep slate-green in dark.
    static let bg = Color.dyn(0xF5F3EC, 0x0C1411)
    /// Raised surfaces (cards, scorecard, trays).
    static let surface = Color.dyn(0xFFFFFF, 0x14211C)
    static let surfaceAlt = Color.dyn(0xEFEDE4, 0x1A2A23)

    /// The felt table itself — a richer green canvas.
    static let felt = Color.dyn(0x1F8A5B, 0x0E4A30)
    static let feltDeep = Color.dyn(0x16744B, 0x0A3A25)

    /// Dice faces — ivory/cream with crisp dark pips.
    static let diceFace = Color.dyn(0xFBF7EC, 0xF3EEDD)
    static let dicePip = Color(hex: 0x21241F)
    static let diceHeld = Color.dyn(0xFFE9A8, 0xFFE39A)

    static let ink = Color.dyn(0x1B201C, 0xF2F4EF)
    static let inkSoft = Color.dyn(0x5E665C, 0xA7B0A6)
    static let hairline = Color.dyn(0xE2E0D6, 0x26342C)

    static let good = Color(hex: 0x18A558)
    static let warn = Color.dyn(0xC9821A, 0xE0A33C)
    static let bad = Color.dyn(0xC0392B, 0xE5675A)
    static let gold = Color.dyn(0xC79A2E, 0xE8C45A)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x18A558), Color(hex: 0x0F7A40)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let feltGradient = LinearGradient(
        colors: [Color.dyn(0x23966A, 0x115437), Color.dyn(0x167049, 0x0A3825)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Corner radii
    static let rSmall: CGFloat = 10
    static let rCard: CGFloat = 18
    static let rLarge: CGFloat = 26

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A consistent raised card surface used across the app.
struct CardBackground: ViewModifier {
    var fill: Color = Theme.surface
    var radius: CGFloat = Theme.rCard
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func card(fill: Color = Theme.surface, radius: CGFloat = Theme.rCard) -> some View {
        modifier(CardBackground(fill: fill, radius: radius))
    }
}
