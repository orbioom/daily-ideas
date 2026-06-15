import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Build a Color from a 0xRRGGBB hex literal.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// A dynamic color that resolves to `l` in light mode and `d` in dark mode.
    static func dyn(_ l: UInt, _ d: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? d : l
            return UIColor(
                red: CGFloat((h >> 16) & 0xFF) / 255,
                green: CGFloat((h >> 8) & 0xFF) / 255,
                blue: CGFloat(h & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

// MARK: - Theme tokens

/// Lantern's visual identity: warm, premium, lantern-lit — deep lacquer reds,
/// ivory tiles, soft gold glow. Calm and uncluttered.
enum Theme {
    // Backgrounds
    static let bg = Color.dyn(0xF6EFE6, 0x140F0D)          // warm ivory paper / near-black lacquer
    static let surface = Color.dyn(0xFFFBF4, 0x231A17)     // raised card
    static let surfaceAlt = Color.dyn(0xF0E6D7, 0x2E2320)  // recessed / muted card

    // Ink (text)
    static let ink = Color.dyn(0x2A1C16, 0xF4ECE2)
    static let inkSoft = Color.dyn(0x6A554A, 0xC4B3A6)
    static let inkFaint = Color.dyn(0x9C8576, 0x8A766B)

    // Accent — deep lacquer red + warm gold glow
    static let accent = Color.dyn(0xB5342C, 0xD24A41)
    static let accentSoft = Color.dyn(0xF1D9D5, 0x3A211E)
    static let gold = Color.dyn(0xC79A4B, 0xE3B968)
    static let goldSoft = Color.dyn(0xF6E9CC, 0x3C3221)

    // Tile colors
    static let tileFace = Color.dyn(0xFCF6EA, 0xEFE6D4)     // ivory tile top (kept light in dark too for readability)
    static let tileFaceShadow = Color.dyn(0xE6D8BF, 0xC9BB9F)
    static let tileEdge = Color.dyn(0xD9C8A6, 0xB8A983)     // beveled side
    static let tileGlyph = Color.dyn(0x2A1C16, 0x2A1C16)

    // Lines / states
    static let hairline = Color.dyn(0xE2D5C2, 0x362A25)
    static let good = Color.dyn(0x4C8C5A, 0x7FC68C)
    static let warn = Color.dyn(0xC98A2B, 0xE3B968)
    static let bad = Color.dyn(0xB5342C, 0xE07065)

    // Fonts
    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }

    // Geometry
    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}

// MARK: - Reusable surface modifier

struct CardSurface: ViewModifier {
    var padding: CGFloat = 16
    var corner: CGFloat = Theme.corner
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(padding: CGFloat = 16, corner: CGFloat = Theme.corner) -> some View {
        modifier(CardSurface(padding: padding, corner: corner))
    }
}
