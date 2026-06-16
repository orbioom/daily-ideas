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

/// Astra's visual identity: cosmic calm — deep violet/navy skies, gold star accents,
/// the zodiac wheel as the hero. Quiet, private, never doom-scroll.
enum Theme {
    // Backgrounds — light lilac by day, deep cosmic navy by night.
    static let bg = Color.dyn(0xF2F0FA, 0x14122A)
    static let surface = Color.dyn(0xFFFFFF, 0x1E1B3A)
    static let surfaceAlt = Color.dyn(0xEAE6F7, 0x272350)

    // Ink (text)
    static let ink = Color.dyn(0x211C3D, 0xF3F0FF)
    static let inkSoft = Color.dyn(0x5C5478, 0xC2BBE0)
    static let inkFaint = Color.dyn(0x8A82A6, 0x7E769E)

    // Accent — violet (matches AccentColor 0x8B7CE8)
    static let accent = Color(hex: 0x8B7CE8)
    static let accentSoft = Color.dyn(0xE6E1FA, 0x2C2655)
    static let accentDeep = Color.dyn(0x6A57C9, 0xAEA0F2)

    /// Gold star accent for highlights, retrograde marks, streak flames.
    static let gold = Color.dyn(0xC79A2E, 0xF5D683)
    static let goldSoft = Color.dyn(0xF6EBCB, 0x3A3320)

    // Lines & status
    static let hairline = Color.dyn(0xE0DBF0, 0x2E2A52)
    static let good = Color.dyn(0x2E9E6B, 0x5FD3A0)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)

    /// A cosmic gradient for hero surfaces (paywall, onboarding, wheel backdrop).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x9B86F0), Color(hex: 0x7A6BD8), Color(hex: 0x4E3FA0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// A deep night-sky gradient used behind the starfield.
    static var skyGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dyn(0xEFEBFB, 0x1A1638), Color.dyn(0xE3DEF6, 0x0F0D22)],
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
