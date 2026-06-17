import SwiftUI

/// The app's design language: clean, trustworthy fintech.
/// Crisp surfaces in light mode, deep slate in dark mode,
/// a confident green accent (#2E9E5B) for "money in your pocket".
enum StubTheme {

    // MARK: - Brand colors

    /// Primary green accent — mirrors the asset catalog AccentColor.
    static let green = Color(red: 0x2E / 255.0, green: 0x9E / 255.0, blue: 0x5B / 255.0)

    /// A deeper green for pressed / emphasis states.
    static let greenDeep = Color(red: 0x24 / 255.0, green: 0x80 / 255.0, blue: 0x49 / 255.0)

    /// A lighter mint used for subtle fills.
    static let mint = Color(red: 0x5C / 255.0, green: 0xC8 / 255.0, blue: 0x8B / 255.0)

    // MARK: - Breakdown / chart palette (stable across modes)

    /// Federal income tax slice.
    static let federal = Color(red: 0xE0 / 255.0, green: 0x6C / 255.0, blue: 0x4F / 255.0)   // warm coral
    /// State income tax slice.
    static let state = Color(red: 0xE8 / 255.0, green: 0xA8 / 255.0, blue: 0x3A / 255.0)      // amber
    /// FICA (Social Security + Medicare) slice.
    static let fica = Color(red: 0x6A / 255.0, green: 0x8C / 255.0, blue: 0xD0 / 255.0)        // steel blue
    /// Take-home slice — the brand green.
    static let takeHome = green

    // MARK: - Adaptive surfaces

    /// App background: near-white in light, deep slate in dark.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x12 / 255.0, green: 0x16 / 255.0, blue: 0x14 / 255.0)
            : Color(red: 0xF5 / 255.0, green: 0xF7 / 255.0, blue: 0xF5 / 255.0)
    }

    /// Card surface — sits above the app background.
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x1C / 255.0, green: 0x22 / 255.0, blue: 0x1E / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)
    }

    /// Subtle raised surface for chips / fields.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x27 / 255.0, green: 0x2F / 255.0, blue: 0x29 / 255.0)
            : Color(red: 0xEC / 255.0, green: 0xF0 / 255.0, blue: 0xEC / 255.0)
    }

    /// Primary text — high contrast in both modes (WCAG AA).
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF1 / 255.0, green: 0xF5 / 255.0, blue: 0xF1 / 255.0)
            : Color(red: 0x16 / 255.0, green: 0x1E / 255.0, blue: 0x18 / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x9C / 255.0, green: 0xA8 / 255.0, blue: 0x9F / 255.0)
            : Color(red: 0x5E / 255.0, green: 0x6A / 255.0, blue: 0x61 / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.07)
    }

    // MARK: - Number typography

    /// A monospaced-digit font for crisp, aligned currency figures.
    static func figureFont(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded).weight(weight).monospacedDigit()
    }
}

// MARK: - Card container

/// A rounded card surface used throughout the app.
struct StubCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(StubTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(StubTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style

struct StubPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEnabled
                          ? (configuration.isPressed ? StubTheme.greenDeep : StubTheme.green)
                          : StubTheme.green.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (outline) button style

struct StubSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(StubTheme.green)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(StubTheme.green.opacity(configuration.isPressed ? 0.26 : 0.14))
            )
    }
}

// MARK: - Chip modifier

struct StubChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundStyle(selected ? Color.white : StubTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? StubTheme.green : StubTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func stubChip(selected: Bool) -> some View { modifier(StubChip(selected: selected)) }
}
