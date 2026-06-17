import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// Resolves a different hex per interface style so colors stay legible in light and dark.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

/// Arcana's visual identity: a starry, candle-lit reading table. Deep violet night skies,
/// luminous gold accents, refined serif headings. Mystical but calm — for reflection, not fortune.
enum Theme {
    // Backgrounds — soft lilac parchment by day, deep cosmic indigo by night.
    static let bg = Color.dyn(0xF4F1FB, 0x120F26)
    static let surface = Color.dyn(0xFFFFFF, 0x1C1838)
    static let surfaceAlt = Color.dyn(0xEDE8F8, 0x252046)

    // Ink (text). Tuned for WCAG-AA contrast in both modes.
    static let ink = Color.dyn(0x1F1A3A, 0xF4F1FF)
    static let inkSoft = Color.dyn(0x554C72, 0xC6BEE2)
    static let inkFaint = Color.dyn(0x7C7398, 0x8B82A8)

    // Accent — mystic violet (matches AccentColor 0x8E54C9).
    static let accent = Color(hex: 0x8E54C9)
    static let accentSoft = Color.dyn(0xEDE1FA, 0x2E2356)
    static let accentDeep = Color.dyn(0x6E3AA8, 0xB78AE8)

    /// Gold highlight — for chosen cards, streak flames, the sun emblem.
    static let gold = Color.dyn(0xB8881E, 0xF3D27E)
    static let goldSoft = Color.dyn(0xF6ECCB, 0x3A3018)

    // Lines & status
    static let hairline = Color.dyn(0xE2DBF2, 0x2C2750)
    static let good = Color.dyn(0x2E9E6B, 0x5FD3A0)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)

    /// A regal violet→gold gradient for hero surfaces (paywall, onboarding, the daily card backdrop).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x9B5CD8), Color(hex: 0x6E3AA8), Color(hex: 0x3C2168)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// A deep night-sky gradient used behind the starfield.
    static var skyGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dyn(0xF0EBFB, 0x191334), Color.dyn(0xE6DEF8, 0x0C0A20)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}

/// Card surface used across the app for a cohesive look.
struct CardBackground: ViewModifier {
    var fill: Color = Theme.surface
    var corner: CGFloat = Theme.corner
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(fill: Color = Theme.surface, corner: CGFloat = Theme.corner) -> some View {
        modifier(CardBackground(fill: fill, corner: corner))
    }
}

/// Section heading used across feature screens — serif, on-brand.
struct SectionHeading: View {
    let title: String
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accentDeep)
            }
            Text(title)
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
        .accessibilityAddTraits(.isHeader)
    }
}
