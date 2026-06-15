import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Build a color from an 0xRRGGBB hex literal.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// A dynamic color that resolves differently for light/dark via the trait collection.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
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

/// Wren's warm, calm, "lived-in" visual identity.
/// Light: warm cream paper. Dark: deep warm charcoal. Coral accent, soft sage "good".
enum Theme {
    // Backgrounds & surfaces
    static let bg = Color.dyn(0xF7F1E9, 0x16130F)
    static let surface = Color.dyn(0xFFFBF4, 0x211C16)
    static let surfaceAlt = Color.dyn(0xF0E7DA, 0x2A241D)

    // Ink (text)
    static let ink = Color.dyn(0x2E2620, 0xF3EDE3)
    static let inkSoft = Color.dyn(0x6B5E50, 0xC4B9A8)
    static let inkFaint = Color.dyn(0xA89A88, 0x7E7264)

    // Accent — terracotta coral
    static let accent = Color.dyn(0xE07A5B, 0xE8896C)
    static let accentSoft = Color.dyn(0xF6D9CD, 0x4A2C22)

    // Lines & status
    static let hairline = Color.dyn(0xE4D9C9, 0x352E25)
    static let good = Color.dyn(0x7E9C73, 0x97B488)   // soft sage
    static let warn = Color.dyn(0xD79A4E, 0xE0AC63)
    static let bad = Color.dyn(0xC2614F, 0xD0735F)

    // Fonts
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    // Geometry
    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
    static let cornerLarge: CGFloat = 26
}

// MARK: - Reusable surface styling

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
    func card(_ fill: Color = Theme.surface, corner: CGFloat = Theme.corner) -> some View {
        modifier(CardBackground(fill: fill, corner: corner))
    }
}
