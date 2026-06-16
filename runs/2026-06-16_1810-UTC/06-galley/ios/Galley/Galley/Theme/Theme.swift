import SwiftUI

/// Galley design language: warm, friendly kitchen.
/// Cream surfaces in light mode, warm charcoal in dark mode,
/// terracotta accent (#C4623E) with a sage secondary.
enum GalleyTheme {

    // MARK: - Brand colors

    /// Terracotta accent — also defined in the asset catalog as AccentColor.
    static let terracotta = Color(red: 0xC4 / 255.0, green: 0x62 / 255.0, blue: 0x3E / 255.0)

    /// A slightly deeper terracotta used for pressed / emphasis.
    static let terracottaDeep = Color(red: 0xA8 / 255.0, green: 0x4F / 255.0, blue: 0x30 / 255.0)

    /// Sage secondary accent.
    static let sage = Color(red: 0x7C / 255.0, green: 0x8A / 255.0, blue: 0x6E / 255.0)
    static let sageDeep = Color(red: 0x5F / 255.0, green: 0x6C / 255.0, blue: 0x53 / 255.0)

    // MARK: - Adaptive surfaces

    /// App background: warm cream in light, warm charcoal in dark.
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x21 / 255.0, green: 0x1E / 255.0, blue: 0x1B / 255.0)
            : Color(red: 0xFB / 255.0, green: 0xF6 / 255.0, blue: 0xEE / 255.0)
    }

    /// Card surface — sits above the app background.
    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x2D / 255.0, green: 0x29 / 255.0, blue: 0x25 / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF8 / 255.0)
    }

    /// Subtle raised surface for chips / fields.
    static func subtleSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0x39 / 255.0, green: 0x34 / 255.0, blue: 0x2F / 255.0)
            : Color(red: 0xF2 / 255.0, green: 0xEA / 255.0, blue: 0xDD / 255.0)
    }

    /// Primary text — high contrast in both modes (WCAG AA).
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xF4 / 255.0, green: 0xEF / 255.0, blue: 0xE8 / 255.0)
            : Color(red: 0x2B / 255.0, green: 0x24 / 255.0, blue: 0x1E / 255.0)
    }

    /// Secondary / muted text.
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0xB7 / 255.0, green: 0xAE / 255.0, blue: 0xA2 / 255.0)
            : Color(red: 0x6E / 255.0, green: 0x63 / 255.0, blue: 0x57 / 255.0)
    }

    /// Hairline separators.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.07)
    }

    static func accent(_ scheme: ColorScheme) -> Color { terracotta }
}

// MARK: - Card container

/// A rounded, tactile card surface used throughout the app.
struct GalleyCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(GalleyTheme.cardSurface(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(GalleyTheme.hairline(scheme), lineWidth: 1)
            )
    }
}

// MARK: - Primary button style

struct GalleyPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
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
                          ? (configuration.isPressed ? GalleyTheme.terracottaDeep : GalleyTheme.terracotta)
                          : GalleyTheme.terracotta.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary (sage outline) button style

struct GalleySecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(GalleyTheme.sageDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(GalleyTheme.sage.opacity(configuration.isPressed ? 0.28 : 0.16))
            )
    }
}

// MARK: - Chip style modifier

struct GalleyChip: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var selected: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.medium))
            .foregroundStyle(selected ? Color.white : GalleyTheme.primaryText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? GalleyTheme.terracotta : GalleyTheme.subtleSurface(scheme))
            )
    }
}

extension View {
    func galleyChip(selected: Bool) -> some View { modifier(GalleyChip(selected: selected)) }
}
