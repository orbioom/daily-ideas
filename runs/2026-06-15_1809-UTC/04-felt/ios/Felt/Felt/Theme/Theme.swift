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

/// Felt's visual identity: a premium green-felt card room — deep felt-green and charcoal
/// surfaces with gold/cream accents. Money is set in monospaced figures.
enum Theme {
    // Backgrounds — warm cream in light, near-black charcoal in dark
    static let bg = Color.dyn(0xF3EFE7, 0x12100D)
    static let surface = Color.dyn(0xFFFFFF, 0x1C1A16)
    static let surfaceAlt = Color.dyn(0xEAE4D8, 0x26231D)

    // The felt — deep table green used on hero surfaces
    static let felt = Color.dyn(0x1F6B4A, 0x123D2C)
    static let feltDeep = Color.dyn(0x14543A, 0x0C2A1E)

    // Ink (text) — AA-contrast in both modes
    static let ink = Color.dyn(0x1A1712, 0xF4F0E7)
    static let inkSoft = Color.dyn(0x564E40, 0xB8B0A0)
    static let inkFaint = Color.dyn(0x857B68, 0x756E5E)

    // Accent — felt green (matches AccentColor 0x2E9E6A)
    static let accent = Color(hex: 0x2E9E6A)
    static let accentSoft = Color.dyn(0xDDF0E6, 0x224033)
    static let accentDeep = Color.dyn(0x1F7A50, 0x52C892)

    // Gold / cream chip accents
    static let gold = Color.dyn(0xB8862B, 0xE6BC5C)
    static let goldSoft = Color.dyn(0xF3E7C9, 0x3A3119)

    // Lines & status. Profit-green / loss-red both pass AA in light and dark.
    static let hairline = Color.dyn(0xE0D9CA, 0x302C24)
    static let good = Color.dyn(0x1C8A52, 0x4FD394)   // profit
    static let warn = Color.dyn(0xB07415, 0xE6B45A)
    static let bad = Color.dyn(0xB23A33, 0xF08077)    // loss

    /// A rich felt gradient for hero surfaces (always dark-on so white text reads).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x1F6B4A), Color(hex: 0x14543A), Color(hex: 0x0C3525)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
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
