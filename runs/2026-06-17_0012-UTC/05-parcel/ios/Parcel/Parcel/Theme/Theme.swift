import SwiftUI

/// Centralized design language for Parcel — a confident, professional study look.
///
/// Light mode uses a warm ivory/paper surface; dark mode a deep warm espresso.
/// The accent (#C9863A amber) lives in the asset catalog as `AccentColor` but is
/// also mirrored here so engine/component code can reference it directly.
enum Theme {

    // MARK: - Core palette

    /// Warm amber accent. Mirrors Assets.xcassets/AccentColor (#C9863A).
    static let accent = Color(red: 0xC9 / 255.0, green: 0x86 / 255.0, blue: 0x3A / 255.0)

    /// A deeper amber/brown for pressed / emphasis states.
    static let accentDeep = Color(red: 0xA5 / 255.0, green: 0x68 / 255.0, blue: 0x28 / 255.0)

    /// A warm gold used for streaks / mastery highlights.
    static let gold = Color(red: 0xD8 / 255.0, green: 0xA8 / 255.0, blue: 0x55 / 255.0)

    /// A muted brick red used sparingly for fail/flag/incorrect states.
    static let brick = Color(red: 0xB2 / 255.0, green: 0x3A / 255.0, blue: 0x2E / 255.0)

    // MARK: - Adaptive surfaces (light ivory / dark espresso)

    /// App background. Warm ivory in light, deep espresso in dark.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1A / 255.0, green: 0x16 / 255.0, blue: 0x11 / 255.0)
            : Color(red: 0xF7 / 255.0, green: 0xF1 / 255.0, blue: 0xE6 / 255.0)
    }

    /// Elevated card surface.
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x27 / 255.0, green: 0x21 / 255.0, blue: 0x1A / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF8 / 255.0)
    }

    /// Secondary card / inset surface.
    static func cardSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x33 / 255.0, green: 0x2C / 255.0, blue: 0x23 / 255.0)
            : Color(red: 0xEF / 255.0, green: 0xE6 / 255.0, blue: 0xD6 / 255.0)
    }

    /// Primary text. High contrast in both modes (WCAG AA).
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF5 / 255.0, green: 0xEF / 255.0, blue: 0xE5 / 255.0)
            : Color(red: 0x2A / 255.0, green: 0x22 / 255.0, blue: 0x18 / 255.0)
    }

    /// Secondary / supporting text. Still meets AA against the surfaces above.
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xBD / 255.0, green: 0xB1 / 255.0, blue: 0xA0 / 255.0)
            : Color(red: 0x6B / 255.0, green: 0x5C / 255.0, blue: 0x48 / 255.0)
    }

    /// Hairline separators / outlines.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.10)
            : Color.black.opacity(0.09)
    }

    /// Success green tuned for AA contrast in both modes.
    static func success(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x6C / 255.0, green: 0xC9 / 255.0, blue: 0x8C / 255.0)
            : Color(red: 0x1F / 255.0, green: 0x73 / 255.0, blue: 0x4A / 255.0)
    }

    /// Error red tuned for AA contrast in both modes.
    static func danger(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xE8 / 255.0, green: 0x6E / 255.0, blue: 0x62 / 255.0)
            : Color(red: 0xB2 / 255.0, green: 0x3A / 255.0, blue: 0x2E / 255.0)
    }

    // MARK: - Typography

    /// Serif display headers — refined, professional, not gaudy.
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

/// A primary call-to-action button style in warm amber.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(isEnabled
                          ? (configuration.isPressed ? Theme.accentDeep : Theme.accent)
                          : Theme.accent.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A subtle secondary button style outlined in the accent color.
struct SecondaryButtonStyle: ButtonStyle {
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
