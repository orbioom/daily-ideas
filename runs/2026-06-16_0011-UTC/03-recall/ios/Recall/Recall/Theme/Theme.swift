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

/// Recall's visual identity: focused, calm study. A deep indigo accent over quiet paper/ink surfaces.
enum Theme {
    // Backgrounds — calm, focused.
    static let bg = Color.dyn(0xF4F4F8, 0x161531)
    static let surface = Color.dyn(0xFFFFFF, 0x211F45)
    static let surfaceAlt = Color.dyn(0xEDEDF4, 0x2A2856)

    // Ink (text)
    static let ink = Color.dyn(0x1E1B33, 0xF1F0FA)
    static let inkSoft = Color.dyn(0x57536E, 0xB7B4D6)
    static let inkFaint = Color.dyn(0x8E8AA6, 0x817EA8)

    // Accent — indigo (matches AccentColor 0x6C5CE7)
    static let accent = Color(hex: 0x6C5CE7)
    static let accentSoft = Color.dyn(0xE7E3FB, 0x2E2A5E)
    static let accentDeep = Color.dyn(0x5546C9, 0x9B8DF2)

    // Lines & status
    static let hairline = Color.dyn(0xE3E2EE, 0x322F5C)
    static let good = Color.dyn(0x1F9E6B, 0x52D6A0)
    static let warn = Color.dyn(0xC97A1F, 0xE9B25C)
    static let bad = Color.dyn(0xC53B3B, 0xEC7E78)

    /// A calm indigo gradient for hero surfaces (paywall, onboarding, study).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x8B7BF0), Color(hex: 0x6C5CE7), Color(hex: 0x5546C9)],
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

    // MARK: - Deck color seeds

    /// Per-seed deck color (background pair). Seeds wrap; each gives a distinct, AA-legible hue.
    static func deckColors(seed: Int) -> (start: Color, end: Color) {
        let palettes: [(UInt, UInt)] = [
            (0x6C5CE7, 0x8B7BF0), // indigo
            (0x2EBFA5, 0x3FD6BA), // teal
            (0xE05780, 0xF06A95), // rose
            (0xF29A4E, 0xF7B267), // amber
            (0x4C8DF6, 0x6FA8FA), // blue
            (0x9B5DE5, 0xB07CF0), // violet
            (0x1F9E6B, 0x3FC189), // green
            (0xE76F51, 0xF0876B)  // coral
        ]
        guard !palettes.isEmpty else { return (accent, accentDeep) }
        let idx = ((seed % palettes.count) + palettes.count) % palettes.count
        let p = palettes[idx]
        return (Color(hex: p.0), Color(hex: p.1))
    }

    /// A linear gradient for a deck card from its color seed.
    static func deckGradient(seed: Int) -> LinearGradient {
        let c = deckColors(seed: seed)
        return LinearGradient(colors: [c.start, c.end],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }
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
