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

/// Tonus' visual identity: calm clinical-warm wellness in soft teal-green.
enum Theme {
    // Backgrounds
    static let bg = Color.dyn(0xF1F7F5, 0x0C1413)
    static let surface = Color.dyn(0xFFFFFF, 0x152120)
    static let surfaceAlt = Color.dyn(0xE6F1ED, 0x1C2B28)

    // Ink (text) — tuned for AA contrast in both modes
    static let ink = Color.dyn(0x14201D, 0xF0F6F4)
    static let inkSoft = Color.dyn(0x44544F, 0xAFC2BC)
    static let inkFaint = Color.dyn(0x6B7C76, 0x76897F)

    // Accent — teal-green (matches AccentColor 0x2C9E8A)
    static let accent = Color(hex: 0x2C9E8A)
    static let accentSoft = Color.dyn(0xD7EFE9, 0x123330)
    static let accentDeep = Color.dyn(0x1F7E6E, 0x57C9B5)

    // Phase colors (calm, distinct, AA legible on surfaces)
    static let squeeze = Color.dyn(0x2C9E8A, 0x4FCBB6)
    static let hold = Color.dyn(0x2E7DB8, 0x6BB6E8)
    static let relax = Color.dyn(0x7A9E5E, 0xA8CB86)
    static let rest = Color.dyn(0x8C8A98, 0xA6A4B4)

    // Lines & status
    static let hairline = Color.dyn(0xDCE9E5, 0x223532)
    static let good = Color.dyn(0x2E9E6B, 0x4FD39A)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)

    /// A calm gradient for hero surfaces.
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x36B19A), Color(hex: 0x2C9E8A), Color(hex: 0x2E7DB8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Soft radial used behind the breathing ring.
    static var ringGlow: RadialGradient {
        RadialGradient(
            colors: [Color(hex: 0x2C9E8A).opacity(0.28), Color(hex: 0x2C9E8A).opacity(0.0)],
            center: .center,
            startRadius: 8,
            endRadius: 220
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
