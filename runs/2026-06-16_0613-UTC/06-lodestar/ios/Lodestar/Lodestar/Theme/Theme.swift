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

    /// Dynamic color that adapts to light / dark interface style.
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

/// Lodestar visual identity — a deep-night planetarium.
/// Near-black navy backgrounds, luminous star-cyan accent, star-gold highlights,
/// fine hairlines, a quiet awe.
enum Theme {
    /// MUST equal AccentColor in Assets (0x5AA9E6).
    static let accent = Color(hex: 0x5AA9E6)

    /// Star-gold highlight for the Moon, the Sun and favourites.
    static let gold = Color(hex: 0xE6C25A)

    /// Page background — near-black navy in dark, a soft dawn-blue in light.
    static let bg = Color.dyn(0xEAF1F8, 0x06080F)

    /// Raised surface (cards, sheets).
    static let surface = Color.dyn(0xFFFFFF, 0x10141F)

    /// Secondary raised surface.
    static let surface2 = Color.dyn(0xF1F5FA, 0x161C2A)

    /// Primary text.
    static let ink = Color.dyn(0x0B1220, 0xF2F6FB)

    /// Secondary text.
    static let inkSoft = Color.dyn(0x4A586B, 0x9AA7BC)

    /// Tertiary / faint text.
    static let inkFaint = Color.dyn(0x7A879A, 0x6A7689)

    /// Fine hairline separators.
    static let hairline = Color.dyn(0xD6DEE9, 0x232A3A)

    static let good = Color.dyn(0x2E8B57, 0x5AD6A0)
    static let warn = Color.dyn(0xB8860B, 0xE6C25A)
    static let bad  = Color.dyn(0xB23A48, 0xF08A8A)

    /// The deep sky disc fill used by the chart.
    static let skyDisc = Color.dyn(0x0E1B3A, 0x040611)
    static let skyRim   = Color.dyn(0x35507F, 0x2A3C66)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x0A1430), Color(hex: 0x121A33), Color(hex: 0x05070E)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let corner: CGFloat = 16
    static let cornerSmall: CGFloat = 10

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A reusable raised card surface in the Lodestar identity.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 0.6)
            )
    }
}

extension View {
    func cardSurface() -> some View { modifier(CardBackground()) }
}
