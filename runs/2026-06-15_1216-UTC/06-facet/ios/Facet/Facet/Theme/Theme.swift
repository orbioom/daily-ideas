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

/// Facet's visual identity: elegant, modern, calm — a gem/facet motif in violet-blue.
enum Theme {
    // Backgrounds
    static let bg = Color.dyn(0xF5F3FB, 0x0E0C16)
    static let surface = Color.dyn(0xFFFFFF, 0x1A1726)
    static let surfaceAlt = Color.dyn(0xEFEBFA, 0x231F33)

    // Ink (text)
    static let ink = Color.dyn(0x1C1830, 0xF3F1FA)
    static let inkSoft = Color.dyn(0x52496E, 0xB7AFD0)
    static let inkFaint = Color.dyn(0x8E86A8, 0x726B8C)

    // Accent — violet-blue (matches AccentColor 0x5A52C8)
    static let accent = Color(hex: 0x5A52C8)
    static let accentSoft = Color.dyn(0xE3E0F8, 0x2C2748)
    static let accentDeep = Color.dyn(0x453DA8, 0x8C84E6)

    // Lines & status
    static let hairline = Color.dyn(0xE2DEF1, 0x2D2840)
    static let good = Color.dyn(0x2E9E6B, 0x4FD39A)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)

    // A calm gradient for hero surfaces
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x6E63E0), Color(hex: 0x5A52C8), Color(hex: 0x3F8FD6)],
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
