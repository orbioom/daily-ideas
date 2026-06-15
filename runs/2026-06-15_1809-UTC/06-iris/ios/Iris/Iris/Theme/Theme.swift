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

/// Iris's visual identity: restful blue-teal calm — soft cool gradients, lots of breathing room.
enum Theme {
    // Backgrounds
    static let bg = Color.dyn(0xEEF5F9, 0x0B1318)
    static let surface = Color.dyn(0xFFFFFF, 0x14202A)
    static let surfaceAlt = Color.dyn(0xE3EEF5, 0x1B2A36)

    // Ink (text)
    static let ink = Color.dyn(0x142730, 0xEAF3F8)
    static let inkSoft = Color.dyn(0x3F5A67, 0xA7C0CE)
    static let inkFaint = Color.dyn(0x6E8794, 0x6F8896)

    // Accent — restful blue-teal (matches AccentColor 0x2F86B8)
    static let accent = Color(hex: 0x2F86B8)
    static let accentSoft = Color.dyn(0xD7EAF4, 0x18313F)
    static let accentDeep = Color.dyn(0x216C97, 0x67B6E0)

    // A secondary teal used for the calming focus target glow.
    static let teal = Color.dyn(0x2FA8A8, 0x57CFCF)

    // Lines & status
    static let hairline = Color.dyn(0xD3E2EC, 0x223543)
    static let good = Color.dyn(0x2E9E6B, 0x4FD39A)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)

    /// A calm cool gradient for hero surfaces.
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x3FA4D6), Color(hex: 0x2F86B8), Color(hex: 0x2F9C9C)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// A soft restful radial used behind full-screen break/exercise moments.
    static func restGradient(_ scheme: ColorScheme) -> RadialGradient {
        let colors: [Color] = scheme == .dark
            ? [Color(hex: 0x16313E), Color(hex: 0x0B1318)]
            : [Color(hex: 0xDDF0F8), Color(hex: 0xC4E2EF)]
        return RadialGradient(colors: colors, center: .center, startRadius: 20, endRadius: 520)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let corner: CGFloat = 20
    static let cornerSmall: CGFloat = 14
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
