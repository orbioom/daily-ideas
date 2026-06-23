import SwiftUI

/// Sprig's design language: fresh, calm, growing. A sage-green identity with
/// warm cream surfaces that stays WCAG-AA legible in both light and dark.
enum Theme {

    // MARK: - Brand

    /// Primary sage accent (#3F8F7A) — matches the asset-catalog AccentColor.
    static let accent = Color(red: 0x3F / 255, green: 0x8F / 255, blue: 0x7A / 255)

    /// A deeper sage for text/foreground on light surfaces (AA contrast).
    static let accentDeep = Color(red: 0x2A / 255, green: 0x63 / 255, blue: 0x54 / 255)

    /// Warm apricot used for accents and the "feed" category.
    static let apricot = Color(red: 0xE2 / 255, green: 0x8E / 255, blue: 0x52 / 255)

    /// Soft sky used for the "sleep" category.
    static let sky = Color(red: 0x5C / 255, green: 0x86 / 255, blue: 0xC4 / 255)

    /// Gentle clay used for the "diaper" category.
    static let clay = Color(red: 0xC0 / 255, green: 0x7A / 255, blue: 0x6E / 255)

    /// Muted gold used for the "growth" category.
    static let gold = Color(red: 0xC2 / 255, green: 0x9B / 255, blue: 0x3E / 255)

    // MARK: - Adaptive surfaces

    /// Primary page background — adapts to color scheme.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x10 / 255, green: 0x17 / 255, blue: 0x14 / 255)
            : Color(red: 0xF4 / 255, green: 0xF8 / 255, blue: 0xF3 / 255)
    }

    /// Elevated card surface.
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1B / 255, green: 0x24 / 255, blue: 0x20 / 255)
            : Color.white
    }

    /// Subtle fill for chips, tiles, secondary buttons.
    static func subtleFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x25 / 255, green: 0x30 / 255, blue: 0x2B / 255)
            : Color(red: 0xE9 / 255, green: 0xF1 / 255, blue: 0xE9 / 255)
    }

    /// Primary text color (AA on both schemes).
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xEF / 255, green: 0xF4 / 255, blue: 0xF0 / 255)
            : Color(red: 0x1C / 255, green: 0x2A / 255, blue: 0x24 / 255)
    }

    /// Secondary / muted text (still AA at ~4.6:1).
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xA6 / 255, green: 0xB6 / 255, blue: 0xAD / 255)
            : Color(red: 0x55 / 255, green: 0x63 / 255, blue: 0x5C / 255)
    }

    /// Hairline separators / borders.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    // MARK: - Gradients

    /// The signature fresh sage backdrop.
    static func ambientGradient(_ scheme: ColorScheme) -> LinearGradient {
        let stops: [Color] = scheme == .dark
            ? [Color(red: 0x12 / 255, green: 0x1C / 255, blue: 0x18 / 255),
               Color(red: 0x10 / 255, green: 0x17 / 255, blue: 0x14 / 255),
               Color(red: 0x14 / 255, green: 0x20 / 255, blue: 0x1B / 255)]
            : [Color(red: 0xEC / 255, green: 0xF5 / 255, blue: 0xEC / 255),
               Color(red: 0xF6 / 255, green: 0xF9 / 255, blue: 0xF4 / 255),
               Color(red: 0xF1 / 255, green: 0xF7 / 255, blue: 0xEF / 255)]
        return LinearGradient(colors: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Accent gradient for primary actions and emblems.
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0x55 / 255, green: 0xA8 / 255, blue: 0x8F / 255),
                     Color(red: 0x2E / 255, green: 0x6E / 255, blue: 0x5C / 255)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Metrics

    static let corner: CGFloat = 20
    static let cardPadding: CGFloat = 16
}
