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

/// Dactyl's visual identity: clean mechanical-keyboard — crisp dark surfaces, mint accent,
/// key-cap motif, monospace for typed text and stats.
enum Theme {
    // Backgrounds
    static let bg = Color.dyn(0xEEF2F1, 0x0C1110)
    static let surface = Color.dyn(0xFFFFFF, 0x161D1C)
    static let surfaceAlt = Color.dyn(0xE3EAE8, 0x1E2725)

    // Keycap surfaces (the mechanical-keyboard motif)
    static let keycap = Color.dyn(0xFCFEFD, 0x222D2B)
    static let keycapShadow = Color.dyn(0xCBD6D3, 0x070B0A)
    static let keycapEdge = Color.dyn(0xD6E0DD, 0x2C3A37)

    // Ink (text)
    static let ink = Color.dyn(0x10201D, 0xEAF4F1)
    static let inkSoft = Color.dyn(0x435551, 0xA6B8B3)
    static let inkFaint = Color.dyn(0x7A8B87, 0x6A7C78)

    // Accent — mint (matches AccentColor 0x4FC9B0)
    static let accent = Color(hex: 0x4FC9B0)
    static let accentSoft = Color.dyn(0xD7F4ED, 0x113330)
    static let accentDeep = Color.dyn(0x2E9E89, 0x6FE0CB)

    // Lines & status
    static let hairline = Color.dyn(0xDCE5E2, 0x283533)
    static let good = Color.dyn(0x2E9E6B, 0x57D69E)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC83C36, 0xF07A72)

    // Typing caret / current char highlight
    static let caret = Color(hex: 0x4FC9B0)

    /// A calm gradient for hero surfaces.
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x4FC9B0), Color(hex: 0x35B3A6), Color(hex: 0x2E9E89)],
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
