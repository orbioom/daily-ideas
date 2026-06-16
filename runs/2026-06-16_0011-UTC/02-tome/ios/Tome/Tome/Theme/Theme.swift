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

/// Tome's visual identity: warm paper / cozy library. Amber accent, serif headings,
/// generated gradient "covers" from a seed. Use `Theme.dyn(...)` everywhere.
enum Theme {
    // Backgrounds — warm parchment in light, deep cocoa in dark.
    static let bg = Color.dyn(0xFBF6EC, 0x1A140C)
    static let surface = Color.dyn(0xFFFFFF, 0x241C12)
    static let surfaceAlt = Color.dyn(0xF3E9D6, 0x2E2417)

    // Ink (text) — warm brown-black for an editorial feel.
    static let ink = Color.dyn(0x2C2113, 0xF5ECDC)
    static let inkSoft = Color.dyn(0x6E5C42, 0xCBB897)
    static let inkFaint = Color.dyn(0x9D8967, 0x8A7657)

    // Accent — warm amber (matches AccentColor 0xD98A2B).
    static let accent = Color.dyn(0xD98A2B, 0xE6A24A)
    static let accentSoft = Color.dyn(0xF7E6CB, 0x3C2D17)
    static let accentDeep = Color.dyn(0xB36E1C, 0xF0B968)

    // Lines & status
    static let hairline = Color.dyn(0xEADCC4, 0x342819)
    static let good = Color.dyn(0x4E8B3D, 0x7CC265)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xBF4B33, 0xE07E64)

    /// A warm gradient for hero surfaces (paywall, onboarding, covers fallback).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xE9A94E), Color(hex: 0xD98A2B), Color(hex: 0xB5651D)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
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
