import SwiftUI

/// Centralized design language for Citizen.
///
/// Light mode uses a warm parchment surface; dark mode a deep federal navy.
/// The accent (#3F6BC4 federal blue) lives in the asset catalog as `AccentColor`
/// but is also mirrored here so engine/preview code can reference it directly.
enum Theme {

    // MARK: - Core palette

    /// Federal blue accent. Mirrors Assets.xcassets/AccentColor (#3F6BC4).
    static let accent = Color(red: 0x3F / 255.0, green: 0x6B / 255.0, blue: 0xC4 / 255.0)

    /// A muted patriotic red used sparingly for fail/flag states.
    static let federalRed = Color(red: 0xB1 / 255.0, green: 0x2A / 255.0, blue: 0x2F / 255.0)

    /// A warm gold used for streaks / mastery highlights.
    static let gold = Color(red: 0xC8 / 255.0, green: 0x9B / 255.0, blue: 0x3C / 255.0)

    // MARK: - Adaptive surfaces (light parchment / dark navy)

    /// App background. Parchment in light, deep navy in dark.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x0C / 255.0, green: 0x14 / 255.0, blue: 0x24 / 255.0)
            : Color(red: 0xF4 / 255.0, green: 0xEC / 255.0, blue: 0xDB / 255.0)
    }

    /// Elevated card surface.
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x15 / 255.0, green: 0x20 / 255.0, blue: 0x38 / 255.0)
            : Color(red: 0xFC / 255.0, green: 0xF7 / 255.0, blue: 0xEC / 255.0)
    }

    /// Secondary card / inset surface.
    static func cardSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1E / 255.0, green: 0x2B / 255.0, blue: 0x46 / 255.0)
            : Color(red: 0xEC / 255.0, green: 0xE1 / 255.0, blue: 0xC8 / 255.0)
    }

    /// Primary text. High contrast in both modes (WCAG AA).
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF2 / 255.0, green: 0xF4 / 255.0, blue: 0xF9 / 255.0)
            : Color(red: 0x1A / 255.0, green: 0x20 / 255.0, blue: 0x2C / 255.0)
    }

    /// Secondary / supporting text. Still meets AA against the surfaces above.
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xA9 / 255.0, green: 0xB6 / 255.0, blue: 0xCB / 255.0)
            : Color(red: 0x52 / 255.0, green: 0x4B / 255.0, blue: 0x3A / 255.0)
    }

    /// Hairline separators / outlines.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.10)
            : Color.black.opacity(0.10)
    }

    /// Success green tuned for AA contrast in both modes.
    static func success(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x5F / 255.0, green: 0xC8 / 255.0, blue: 0x8B / 255.0)
            : Color(red: 0x1E / 255.0, green: 0x7A / 255.0, blue: 0x4E / 255.0)
    }

    // MARK: - Typography

    /// Serif display headers — refined, not gaudy.
    ///
    /// Built on a `TextStyle` so they scale with Dynamic Type. The `size` overload
    /// maps a requested point size to the nearest text style, then applies the serif
    /// design and weight, so custom-sized headers still scale for accessibility.
    static func serifTitle(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(textStyle(for: size), design: .serif).weight(weight)
    }

    /// Map a nominal point size to a Dynamic-Type text style.
    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<14: return .footnote
        case ..<16: return .subheadline
        case ..<18: return .callout
        case ..<20: return .body
        case ..<22: return .title3
        case ..<26: return .title2
        case ..<32: return .title
        default: return .largeTitle
        }
    }

    static var largeTitle: Font { .system(.largeTitle, design: .serif).weight(.bold) }
    static var title: Font { .system(.title, design: .serif).weight(.semibold) }
    static var sectionTitle: Font { .system(.title3, design: .serif).weight(.semibold) }

    // MARK: - Metrics

    static let corner: CGFloat = 16
    static let cardPadding: CGFloat = 16
}

// MARK: - Reusable surfaces

/// A standard rounded card surface that adapts to color scheme.
struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var secondary: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(secondary ? Theme.cardSecondary(scheme) : Theme.card(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.hairline(scheme), lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(secondary: Bool = false) -> some View {
        modifier(CardBackground(secondary: secondary))
    }

    /// Applies the app background that fills the safe area.
    func screenBackground(_ scheme: ColorScheme) -> some View {
        background(Theme.background(scheme).ignoresSafeArea())
    }
}

/// A primary call-to-action button style in federal blue.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.accent.opacity(isEnabled ? 1.0 : 0.4))
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

/// A subtle secondary button style outlined in the accent color.
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(0.6), lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
