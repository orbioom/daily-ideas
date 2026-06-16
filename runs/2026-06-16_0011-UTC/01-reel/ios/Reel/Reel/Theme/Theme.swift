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

/// Reel's visual identity: cinematic and dark-friendly — a theater-dim canvas, a single bold
/// red accent, and generated gradient "posters" derived from a stored color seed.
enum Theme {
    // Backgrounds — theater-dim, calm in both modes.
    static let bg = Color.dyn(0xF6F3EE, 0x0E0F14)
    static let surface = Color.dyn(0xFFFFFF, 0x181A22)
    static let surfaceAlt = Color.dyn(0xEFEAE1, 0x20232E)

    // Ink (text)
    static let ink = Color.dyn(0x1A1B22, 0xF4F1EA)
    static let inkSoft = Color.dyn(0x55585F, 0xB6B2A8)
    static let inkFaint = Color.dyn(0x8C8A86, 0x726F69)

    // Accent — cinematic red (matches AccentColor 0xE63950)
    static let accent = Color(hex: 0xE63950)
    static let accentSoft = Color.dyn(0xFBE0E4, 0x361A20)
    static let accentDeep = Color.dyn(0xC02338, 0xFF6E80)

    // Lines & status
    static let hairline = Color.dyn(0xE3DCCF, 0x282B36)
    static let good = Color.dyn(0x2E9E6B, 0x4FD39A)
    static let warn = Color.dyn(0xC9821F, 0xE8B25C)
    static let bad = Color.dyn(0xC2453F, 0xE88078)

    // Star rating gold.
    static let gold = Color.dyn(0xE0A21A, 0xF5C543)

    /// A cinematic red gradient for hero surfaces (paywall, onboarding, buttons).
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xFF5C72), Color(hex: 0xE63950), Color(hex: 0xA01B2E)],
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

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12

    // MARK: - Generated poster gradients

    /// A small, hand-tuned palette of cinematic two-stop gradients. The colorSeed picks
    /// one deterministically so a Title always renders the same "poster".
    private static let posterPalettes: [(UInt, UInt)] = [
        (0xE63950, 0x6A1024), // crimson
        (0x2C3E73, 0x0E1530), // midnight blue
        (0x1F7A6B, 0x0C3A33), // emerald
        (0x7A3FB0, 0x2E1450), // violet
        (0xC9821F, 0x5A3508), // amber
        (0xB83A60, 0x4A0F26), // magenta
        (0x2E6E9E, 0x0F2C44), // ocean
        (0x4A5240, 0x1C2016), // olive
        (0xD1543A, 0x5C1A0E), // ember
        (0x3F6B8F, 0x152C3C), // steel
        (0x8A5A2B, 0x3A2410), // bronze
        (0x556070, 0x21262E), // slate
    ]

    /// Resolve a poster gradient for a given seed (any Int). Deterministic, light/dark aware.
    static func posterGradient(seed: Int) -> LinearGradient {
        let count = posterPalettes.count
        let idx = ((seed % count) + count) % count
        let pair = posterPalettes[idx]
        let top = Color.dyn(pair.0, brighten(pair.1))
        let bottom = Color.dyn(darken(pair.0), pair.1)
        return LinearGradient(colors: [top, bottom],
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }

    /// A flat representative color for the seed (used for chips / small swatches).
    static func posterColor(seed: Int) -> Color {
        let count = posterPalettes.count
        let idx = ((seed % count) + count) % count
        return Color(hex: posterPalettes[idx].0)
    }

    private static func darken(_ hex: UInt) -> UInt {
        let r = UInt(Double((hex >> 16) & 0xFF) * 0.72)
        let g = UInt(Double((hex >> 8) & 0xFF) * 0.72)
        let b = UInt(Double(hex & 0xFF) * 0.72)
        return (r << 16) | (g << 8) | b
    }

    private static func brighten(_ hex: UInt) -> UInt {
        let r = min(255, UInt(Double((hex >> 16) & 0xFF) * 1.3 + 12))
        let g = min(255, UInt(Double((hex >> 8) & 0xFF) * 1.3 + 12))
        let b = min(255, UInt(Double(hex & 0xFF) * 1.3 + 12))
        return (r << 16) | (g << 8) | b
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
